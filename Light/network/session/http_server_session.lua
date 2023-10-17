--- Light.lua
--- Light up your way to the internet
--- @module 'HttpServerSession'
--- @author Jakit Liang 泊凛
--- @date 2023-09-16
--- @license MIT

local Object = require('core.object')
local Socket = require('socket')
local TCPServerSession = require('core.network.session.tcp_server_session')
local HttpSession = require('core.network.session.http_session')
local HttpSessionDelegate = HttpSession.Delegate
local Log = require('core.log')

--- @class HttpServerSession : TCPServerSession
--- @field clients TCPChannel[]
--- @field delegate HttpServerSessionDelegate
--- @field [Channel] HttpSession
--- @overload fun(host: string, port: integer, count: integer, delegate):self
local HttpServerSession = {}

--- @class HttpServerSessionDelegate : HttpSessionDelegate
local HttpServerSessionDelegate = {}

function HttpServerSessionDelegate:onJoin(session) end

function HttpServerSessionDelegate:onLeave(session) end

Object(HttpServerSessionDelegate)
HttpServerSessionDelegate:extends(HttpSessionDelegate)

function HttpServerSession:new(host, port, count, delegate)
  TCPServerSession.new(self, host, port, count)
  self.delegate = delegate
end

--- @param tcpServerChannel TCPServerChannel
--- @param tcpChannel TCPChannel
function HttpServerSession:onAccept(tcpServerChannel, tcpChannel)
  local host, port = tcpChannel:getAddress()
  local delegate = self.delegate
  local session = HttpSession(host, port, delegate, tcpChannel)
  self[tcpChannel] = session
  -- Log:debug("HttpServerSession:onAccept", tostring(tcpChannel), host, port)

  if delegate then
    if type(delegate) == 'function' then
      delegate('onJoin', session)
      return
    end

    delegate.onJoin(session)
  end
end

function HttpServerSession:onClose(channel)
  -- Log:debug("HttpServerSession:onClose", tostring(channel))
  local delegate = self.delegate
  local session = self[channel]
  TCPServerSession.onClose(self, channel)

  if delegate then
    if type(delegate) == 'function' then
      delegate('onLeave', session)
      return
    end

    delegate.onLeave(session)
  end
end

Object(TCPServerSession, HttpServerSession)

HttpServerSession.Delegate = HttpServerSessionDelegate

return HttpServerSession
