local app = require("./lus/websocket").WebSocket:new()

app:listen({port=8001}, function(net)
	p("-- [Server]onListen", net:peeraddress().ip..":"..net:peeraddress().port)
end, function(net, data)
	p("-- [Server]onReceive", data, net:peeraddress().ip..":"..net:peeraddress().port)
	net:send(data)
end, function(net)
	p("-- [Server]onClose")
end)
print("================= Server listen at", "websocket://"..app._ip..":"..app._port)