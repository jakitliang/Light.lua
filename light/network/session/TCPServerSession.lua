--- Light.lua
--- Light up your way to the internet
--- @module 'TCPServerSession'
--- @author Jakit Liang 泊凛
--- @date 2023-10-16
--- @license MIT

local Object = require('light.Object')
local TCPSession = require('light.network.session.TCPSession')
local TCPServerChannel = require('light.network.channel.TCPServerChannel')
local Log = require('light.Log')

--- @class TCPServerSession : TCPSession, TCPServerChannelDelegate
--- @field channel TCPServerChannel
--- @field [Channel] TCPSession
local TCPServerSession = {}

function TCPServerSession:new(host, port, count)
  TCPSession.new(self, host, port, TCPServerChannel(host, port, count or 200, self))
end

function TCPServerSession:onRead(channel, buffer)
  -- Log:debug("TCPServerSession:onRead", tostring(channel))
  return self[channel]:onRead(channel, buffer)
end

function TCPServerSession:onWrite(channel, size)
  -- Log:debug("TCPServerSession:onWrite", tostring(channel), size)
  return self[channel]:onWrite(channel, size)
end

function TCPServerSession:onClose(channel)
  -- Log:debug("TCPServerSession:onClose", tostring(channel))
  self[channel]:onClose(channel)
  self[channel] = nil
end

--- @param tcpServerChannel TCPServerChannel
--- @param tcpChannel TCPChannel
function TCPServerSession:onAccept(tcpServerChannel, tcpChannel)
  local host, port = tcpChannel:getAddress()
  self[tcpChannel] = TCPSession(host, port, tcpChannel)
  -- Log:debug("TCPServerSession:onAccept", tostring(tcpChannel), host, port)
end

function TCPServerSession:close()
  for k, v in pairs(self) do
    if v.channel then
      v:close()
      rawset(self, k, nil)
    end
  end

  TCPSession.close(self)
end

--- @param buffer string
--- @param size? integer
function TCPServerSession:send(channel, buffer, size)
  self[channel]:send(buffer, size)
end

Object(TCPSession, TCPServerSession)
TCPServerSession:extends(TCPServerChannel.Delegate)

return TCPServerSession
