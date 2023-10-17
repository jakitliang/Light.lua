
local Object = require('core.object')
local Socket = require('socket')
local TCPChannel = require('core.network.channel.tcp_channel')
local EventWorker = require('core.worker.event_worker')
local Log = require('core.log')

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
  local io = Socket.TCP()

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

  elseif err == Socket.Errno.EAGAIN then
    return EventWorker.Handle.CONTINUE

  elseif err == Socket.Errno.EWOULDBLOCK then
    return EventWorker.Handle.CONTINUE
  end

  return EventWorker.Handle.ERROR
end

Object(TCPChannel, TCPServerChannel)
TCPServerChannel.Delegate = TCPServerChannelDelegate

return TCPServerChannel
