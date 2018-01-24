# lus - Building blazing fast WebSocket application

## Install
- Install Luvit

    curl -L https://github.com/luvit/lit/raw/master/get-lit.sh | sh

- Install LuaRocks

    wget https://luarocks.org/releases/luarocks-2.4.3.tar.gz

    tar zxpf luarocks-2.4.3.tar.gz

    cd luarocks-2.4.3

    ./configure; make bootstrap

- Install lua-websockets

    luarocks install lua-websockets

- Install rapidjson(optional)

    luarocks install rapidjson

- Install luasql(optional)

    luarocks install luasql-sqlite3

    luarocks install luasql-postgres

    luarocks install luasql-mysql

## Usage
- echo.lua
```Lua
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
```
Run:

    luvit echo.lua

- JavaScript WS RPC Client(require lus/ws.js)
```JavaScript
var ws = WS.new();
ws.connect({host:'ws://127.0.0.1:8001',enc:'json'},
function(e) {
  ws.send("hello");
},
function(data) {
  console.log("[onMessage]"+data);
},
function(e) {
  console.log("[onClose]"+e);
},
function(e) {
  console.log("[onError]"+e);
});
```

- user.lua(with db)
```Lua

```

- JavaScript WS RPC Client(require lus/ws.js)
```JavaScript
var ws = WS.new();
ws.connect({host:'ws://127.0.0.1:8002',enc:'json'},
function(e) {
  ws.Emit("User", {id:1});
  ws.on("User", function(data){
    console.log("User", data.user);
  });
},
function(data) {
  console.log("[onMessage]"+data);
},
function(e) {
  console.log("[onClose]"+e);
},
function(e) {
  console.log("[onError]"+e);
});
```

## Benchmark
- luvit bench_raw.lua

    Requests per second: 60000 #/sec

- luvit bench.lua

    Requests per second: 24000 #/sec
