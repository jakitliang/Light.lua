
io.stdout:setvbuf('no')

local HttpSession = require('light.network.session.http_session')
local WebSocketProtocol = require('light.network.protocol.websocket_protocol')

local s = HttpSession('127.0.0.1', 8080, function (action, ...)
  print('action:', action)
  if action == 'onHttp' then
    --- @type HttpSession, HttpProtocol, HttpProtocol
    local self, input, output = ...
    output.headers['connection'] = input.headers['connection']
    return output

  elseif action == 'onWebSocket' then
    --- @type HttpSession, WebSocketProtocol, WebSocketProtocol
    local self, input, output = ...
    print('onWebSocket:', input.payload)
  end

  return nil
end)

s:sendHandShake()

local count = 1
local t1 = os.time()

while true do
  local t2 = os.time()
  s:resume()

  if t2 - t1 > 5 then
    t1 = t2
    count = count + 1

    local request = WebSocketProtocol()
    request.mask = true
    request.opCode = WebSocketProtocol.OpCode.OP_TEXT
    request.payload = string.format("Hello <%d> times", count)
    s:send(request)
  end
end
