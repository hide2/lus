local os = require('ffi').os
local env = require('env')
local tmpdir = os == 'Windows' and env.get('TMP') or '/tmp'
local db = require("./lus/db").DB:new("sqlite3", tmpdir.."/test.sqlite3")
local User = require("./lus/db").Model:extend():new(db)
local app = require("./lus/websocket").WebSocket:new()

-- prepare db
User.db:run"DROP TABLE user"
User.db:run[[
  CREATE TABLE user(
    id  INT PRIMARY KEY,
    name  VARCHAR(50),
    email VARCHAR(50)
  )
]]
local list = {
	{ id=1, name="Jose das Couves", email="jose@couves.com", },
	{ id=2, name="Jack", email="manoel.joaquim@cafundo.com", },
	{ id=3, name="Jack", email="maria@dores.com", },
}

print("------------------------ User:save")
for i, p in pairs (list) do
	User:save({id=p.id, name=p.name, email=p.email})
end

print("------------------------ User:all")
p(User:all())

print("------------------------ User:find(1)")
p(User:find(1))
print("------------------------ User:find(4)")
p(User:find(4))

print("------------------------ User:where({name='Jack'})")
p(User:where({name='Jack'}))
print("------------------------ User:where(where({name='Jack',email='maria@dores.com'})")
p(User:where({name='Jack',email='maria@dores.com'}))

print("------------------------ User:update({name='Jack2'},{email='maria@dores.com'})")
p(User:update({name='Jack2'},{email='maria@dores.com'}))
print("------------------------ User:where({name='Jack2'})")
p(User:where({name='Jack2'}))

print("------------------------ User:destroy({id=2})")
p(User:destroy({id=2}))
print("------------------------ User:destroy({name='Jack2'})")
p(User:destroy({name='Jack2'}))
print("------------------------ User:all")
p(User:all())

app:listen({port=8002,enc='json'}, function(net)
	p("-- [Server]onListen", net:peeraddress().ip..":"..net:peeraddress().port)
	net:on('User', function(args)
		print("= [Server]on User", args.id)
		local user = User:find(args.id)
		net:Emit('User', {user=user})
	end)
end, function(net, data)
	p("-- [Server]onReceive", data, net:peeraddress().ip..":"..net:peeraddress().port)
end, function(net)
	p("-- [Server]onClose")
end)
print("================= Server listen at", "websocket://"..app._ip..":"..app._port)