
io.stdout:setvbuf('no')

package.path = "..\\?.lua;" .. "" .. package.path

local Log = require('light.log')
Log.level = Log.Level.DEBUG

local HttpServerSession = require('light.network.session.http_server_session')

local s = HttpServerSession('127.0.0.1', 3001, 200, function (action, ...)
  -- print('action:', action)
  if action == 'onHttp' then
    --- @type HttpSession, HttpProtocol, HttpProtocol
    local self, input, output = ...
    return output
  end

  return nil
end)

while true do
  s:resume()
end
