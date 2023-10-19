--- Light.lua
--- Light up your way to the internet
--- @module 'TCPSession'
--- @author Jakit Liang 泊凛
--- @date 2023-09-16
--- @license MIT

local Object = require('light.object')
local Session = require('light.network.session')
local TCPChannel = require('light.network.channel.tcp_channel')
local Log = require('light.log')

--- @class TCPSession : Session, TCPChannelDelegate
--- @field channel TCPChannel
--- @overload fun(host: string, port: integer, channel?: TCPChannel):self
local TCPSession = {}

function TCPSession.__index(t, k)
  if k == 'address' then
    return t.channel.io:getAddress()
  end
end

function TCPSession:new(host, port, channel)
  self.host, self.port = host, port
  Session.new(self, channel or TCPChannel(host, port, self))
end

function TCPSession:onRead(channel, buffer)
  -- Log:debug("TCPSession:onRead", tostring(channel), buffer)
  self:send(buffer, #buffer)
  return #buffer
end

function TCPSession:onWrite(channel, size)
  -- Log:debug("TCPSession:onWrite", tostring(channel), size)
  self:dequeue(size)
end

function TCPSession:onClose(channel)
  -- Log:debug("TCPSession:onClose", tostring(channel))
end

--- @param buffer string
--- @param size? integer
function TCPSession:send(buffer, size)
  size = size or buffer:len()
  self:enqueue(size)
  self.channel:writeAsync(buffer, size)
end

Object(Session, TCPSession)

TCPSession:extends(TCPChannel.Delegate)

return TCPSession
