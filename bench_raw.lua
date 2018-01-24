local WebSocket = require("./lus/websocket").WebSocket

local app = WebSocket:new()
app:listen({port=8881}, function(net)
end, function(net, data)
  net:send(data)
end, function()
end)
print("================= Server listen at", "websocket://"..server._ip..":"..server._port)

local PORT = 8881
local HOST = "127.0.0.1"
local C = 1000
local N = 1000000
local totalTime = 0
local totalN = 0
local totalSize = 0
local startTime = os.time()

local function chain()
  local client = WebSocket:new()
  client:connect({ip=HOST,port=PORT}, function(net)
    client:send("hello")
  end, function(net, data)
    totalSize = totalSize + #data
    totalN = totalN + 1
    if totalN < N then
      if totalN % (N/10) == 0 then
        print("Completed ", totalN, "requests")
      end
      client:send("hello")
    else
      print("Completed ", totalN, "requests\n")
      print("Concurrency Level:", C)
      local timeTaken = os.time() - startTime
      print("Time taken for tests:", timeTaken, "seconds")
      print("Total transferred:", totalSize, "bytes")
      print("Request size:", totalSize/totalN, "bytes")
      print("Requests per second:", N/timeTaken, "[#/sec]")
      os.exit()
    end
  end, function()
  end)
end

print("\nBenchmarking ", HOST, "(be patient)\n")
for i = 1,C do
  chain()
end

-- 6w r/s