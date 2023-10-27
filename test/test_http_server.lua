
io.stdout:setvbuf('no')

package.path = "..\\?.lua;" .. "" .. package.path

local Log = require('light.Log')
Log.level = Log.Level.DEBUG

local HttpServerSession = require('light.network.session.HttpServerSession')

local s = HttpServerSession('127.0.0.1', 3001, 200, function (action, ...)
  Log:debug('action:', action)
  if action == 'onHttp' then
    --- @type HttpSession, HttpProtocol, HttpProtocol
    local self, input, output = ...
    return output

  elseif action == 'onWebSocket' then
    -- 业务逻辑
    --- @type HttpSession, WebSocketProtocol, WebSocketProtocol
    local self, input, output = ...
    Log:debug(input.payload, input.payload:len())
  end

  return nil
end)

while true do
  s:resume()
end
