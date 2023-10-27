
io.stdout:setvbuf('no')

package.path = "..\\?.lua;" .. "" .. package.path

local Log = require('light.Log')
Log.level = Log.Level.DEBUG

local HttpSession = require('light.network.session.HttpSession')
local WebSocketProtocol = require('light.network.protocol.WebSocketProtocol')

local s = HttpSession('127.0.0.1', 8080, function (action, ...)
  Log:debug('action:', action)
  if action == 'onHttp' then
    --- @type HttpSession, HttpProtocol, HttpProtocol
    local self, input, output = ...
    output.headers['connection'] = input.headers['connection']
    return output

  elseif action == 'onWebSocket' then
    --- @type HttpSession, WebSocketProtocol, WebSocketProtocol
    local self, input, output = ...
    Log:debug('onWebSocket:', input.payload)
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
