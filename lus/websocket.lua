local uv = require('uv')
local Emitter = require('core').Emitter
local los = require('los')
local tools = require('websocket.tools')
local frame = require('websocket.frame')
local handshake = require('websocket.handshake')
local JSON = require('rapidjson')

local WebSocket = Emitter:extend()

function WebSocket:initialize(options)
	if options and options.handle then
		self._handle = options.handle
	else
		self._handle = uv.new_tcp()
	end
end

function WebSocket:bind(options)
	self._enc = options and options.enc
	self._ip = options and options.ip or '0.0.0.0'
	self._port = tonumber(options and options.port or 8080)
	self._queueSize = options and options.queueSize or 128
	uv.tcp_bind(self._handle, self._ip, self._port)
end

function WebSocket:listen(options, onListen, onReceive, onClose)
	self._enc = options and options.enc
	self._ip = options and options.ip or '0.0.0.0'
	self._port = tonumber(options and options.port or 8080)
	self._queueSize = options and options.queueSize or 128
	uv.tcp_bind(self._handle, self._ip, self._port)
	self._onListen = onListen
	local ret = uv.listen(self._handle, self._queueSize, function()
		local client = uv.new_tcp()
		uv.tcp_keepalive(self._handle, true, 60)
		uv.tcp_keepalive(client, true, 60)
		uv.accept(self._handle, client)
		local clientSocket = WebSocket:new({ handle = client })
		clientSocket._enc = self._enc
		clientSocket._onReceive = onReceive
		clientSocket._onClose = onClose
		self:onListen(clientSocket)

		client:read_start(function(err, data)
			if err then
				-- p("[Server]err", err)
				clientSocket:onClose()
				if not client:is_closing() then
					client:close()
				end
			end
			if data then
				-- p("[Server]data", data)
				-- 握手
				if not clientSocket._handshaked then
					clientSocket:handshake(clientSocket, data)
				else
					local frames = {}
					repeat
						local decoded,fin,opcode,rest = frame.decode(data)
						if decoded then
							if not clientSocket._first_opcode then
								clientSocket._first_opcode = opcode
							end
							table.insert(frames,decoded)
							data = rest
							if fin == true then
								clientSocket:onReceive(clientSocket, table.concat(frames))
								frames = {}
								clientSocket._first_opcode = nil
							end
						end
					until not decoded
				end
			else
				-- p("[Server]close")
				clientSocket:onClose()
				if not client:is_closing() then
					client:close()
				end
			end
		end)

	end)
	assert(ret >= 0, 'listen error:'..ret)
end

function WebSocket:onListen(client)
	if self._onListen then
		self._onListen(client)
	end
end

function WebSocket:handshake(client, data)
	-- local res, err = handshake.accept_upgrade(data)
	local res, err
	local headers = {}
	if data:match('.*HTTP/1%.1') then
		data = data:match('[^\r\n]+\r\n(.*)')
		local empty_line
		for line in data:gmatch('[^\r\n]*\r\n') do
			local name,val = line:match('([^%s]+)%s*:%s*([^\r\n]+)')
			if name and val then
				name = name:lower()
				if not name:match('sec%-websocket') then
					val = val:lower()
				end
				if not headers[name] then
					headers[name] = val
				else
					headers[name] = headers[name]..','..val
				end
			elseif line == '\r\n' then
				empty_line = true
			else
				assert(false,line..'('..#line..')')
			end
		end
	end
	if headers['upgrade'] ~= 'websocket' or
	not headers['connection'] or
	not headers['connection']:match('upgrade') or
	headers['sec-websocket-key'] == nil or
	headers['sec-websocket-version'] ~= '13' then
		res, err = nil,'HTTP/1.1 400 Bad Request\r\n\r\n'
	end
	local lines = {
		'HTTP/1.1 101 Switching Protocols',
		'Upgrade: websocket',
		'Connection: Upgrade',
		'Sec-WebSocket-Version: 13',
		'Server: X',
		string.format('Sec-WebSocket-Accept: %s',handshake.sec_websocket_accept(headers['sec-websocket-key'] or 'foo')),
		'\r\n',
	}
	res, err = table.concat(lines,'\r\n')

	if res then
		client._handle:write(res)
		client._handshaked = true
	else
		client._handle:write(err)
		client:close()
	end
end

function WebSocket:onReceive(client, data)
	if data == '\003\233' then return end
	if self._onReceive then
		self._onReceive(client, data)
	end

	if self._enc == 'json' then
		data = JSON.decode(data)
		if data and data._E then
			self:emit(data._E, data._A)
		end
	end
end

function WebSocket:onClose()
	if self._onClose then
		self._onClose(self)
	end
end

function WebSocket:Emit(event, args)
	if self._enc ~= 'json' then return end
	local data = JSON.encode({_E=event, _A=args})
	data = frame.encode(data, self._first_opcode or frame.TEXT)
	self._handle:write(data)
end

function WebSocket:EmitBroadcast(nets, event, args)
	if self._enc ~= 'json' then return end
	local data = JSON.encode({_E=event, _A=args})
	data = frame.encode(data, self._first_opcode or frame.TEXT)
	for _, net in next, nets do
		net._handle:write(data)
	end
end

function WebSocket:send(data)
	data = (self._enc == 'json') and JSON.encode(data) or data
	data = frame.encode(data, self._first_opcode or frame.TEXT)
	self._handle:write(data)
end

function WebSocket:broadcast(nets, data)
	data = (self._enc == 'json') and JSON.encode(data) or data
	data = frame.encode(data, self._first_opcode or frame.TEXT)
	for _, net in next, nets do
		net._handle:write(data)
	end
end

function WebSocket:sendhandshake(options)
	local lines = {
		string.format('GET %s HTTP/1.1', options and options.path or '/'),
		string.format('Host: %s', options and options.host or 'localhost'),
		'Upgrade: websocket',
		'Connection: Upgrade',
		string.format('Sec-WebSocket-Key: %s', tools.generate_key()),
		'Sec-WebSocket-Version: 13',
		'\r\n',
	}
	local data = table.concat(lines,'\r\n')
	self._handle:write(data)
end

function WebSocket:close()
	self:onClose()
	self._handle:close()
end

function WebSocket:address()
	uv.tcp_getsockname(self._handle)
end

function WebSocket:peeraddress()
	return uv.tcp_getpeername(self._handle)
end

function WebSocket:connect(options, onConnect, onReceive, onClose)
	self._enc = options and options.enc
	self._ip = options and options.ip or '127.0.0.1'
	self._port = tonumber(options and options.port or 8080)
	self._onConnect = onConnect
	self._onReceive = onReceive
	self._onClose = onClose
	if not self._handle then
		self._handle = uv.new_tcp()
	end
	local client = self._handle
	client:connect(self._ip, self._port, function(err)
		if err then error(err) end

		-- 握手
		self:sendhandshake(options)

		client:read_start(function(err, data)
			if err then
				-- p("[Client]err", err)
				self:onClose()
				if not client:is_closing() then
					client:close()
				end
			end
			if data then
				-- p("[Client]data", data)
				-- 握手成功
				if data:match('Sec%-WebSocket%-Accept') then
					self._handshaked = true
					self:onConnect()
				else
					local frames = {}
					repeat
						local decoded,fin,opcode,rest = frame.decode(data)
						if decoded then
							if not self._first_opcode then
								self._first_opcode = opcode
							end
							table.insert(frames,decoded)
							data = rest
							if fin == true then
								self:onReceive(self, table.concat(frames))
								frames = {}
								self._first_opcode = nil
							end
						end
					until not decoded
				end
			else
				-- p("[Client]close")
				self:onClose()
				if not client:is_closing() then
					client:close()
				end
			end

		end)

	end)
end

function WebSocket:onConnect()
	if self._onConnect then
		self._onConnect(self)
	end
end

return {
		WebSocket = WebSocket,
}