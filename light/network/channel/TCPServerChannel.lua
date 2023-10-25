--- Light.lua
--- Light up your way to the internet
--- @module 'TCPServerChannel'
--- @author Jakit Liang 泊凛
--- @date 2023-10-16
--- @license MIT

local Object = require('light.Object')
local socket = require('light.socket')
local TCPChannel = require('light.network.channel.TCPChannel')
local EventWorker = require('light.worker.EventWorker')
local Log = require('light.Log')

--- @class TCPServerChannel : TCPChannel, EventWorker
--- @field host string
--- @field port integer
--- @field delegate TCPServerChannelDelegate
--- @overload fun(host: string, port: integer, count: integer, delegate?: TCPServerChannelDelegate, socket):self
local TCPServerChannel = {}

--- @class TCPServerChannelDelegate : TCPChannelDelegate
local TCPServerChannelDelegate = Object()
TCPServerChannelDelegate:extends(TCPChannel.Delegate)

--- @param tcpServerChannel TCPServerChannel
--- @param tcpChannel TCPChannel
function TCPServerChannelDelegate:onAccept(tcpServerChannel, tcpChannel) end

local function TCPServerChannelInitIO(self, host, port, count)
  local io = socket.TCP()

  io:bind(host, port)
  io:listen(count)

  return io
end

function TCPServerChannel:new(host, port, count, delegate, io)
  io = io or TCPServerChannelInitIO(self, host, port, count or 200)
  TCPChannel.new(self, host, port, delegate, io)
  EventWorker:add(self, 'r')
end

function TCPServerChannel:accept()
  local client, err = self.io:accept()

  if client then
    return TCPChannel('', 0, self.delegate, client), 0
  end

  return nil, err
end

function TCPServerChannel:acceptNow()
  local client, err = self.io:acceptNow()

  if client then
    return TCPChannel('', 0, self.delegate, client), 0
  end

  return nil, err
end

--- @param event EventWorker
function TCPServerChannel:onReadEvent(event)
  -- Log:debug('TCPServerChannel:onReadEvent', tostring(self))
  self.active = os.time()

  local channel, err = self:acceptNow()

  if channel then
    if self.delegate then
      self.delegate:onAccept(self, channel)
    end

    return EventWorker.Handle.CONTINUE

  elseif err == socket.Errno.EAGAIN then
    return EventWorker.Handle.CONTINUE

  elseif err == socket.Errno.EWOULDBLOCK then
    return EventWorker.Handle.CONTINUE
  end

  return EventWorker.Handle.ERROR
end

Object(TCPChannel, TCPServerChannel)
TCPServerChannel.Delegate = TCPServerChannelDelegate

return TCPServerChannel
