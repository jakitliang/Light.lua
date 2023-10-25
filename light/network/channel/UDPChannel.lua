--- Light.lua
--- Light up your way to the internet
--- @module 'UDPChannel'
--- @author Jakit Liang 泊凛
--- @date 2023-10-16
--- @license MIT

local Object = require('light.Object')
local Socket = require('light.socket')
local Channel = require('light.network.Channel')
local EventWorker = require('light.worker.EventWorker')
local Log = require('light.Log')

--- UDPChannel is used to create UDP socket connection<br>
--- Default is blocking. For async usage should have delegate given
--- @class UDPChannel : Channel, EventWorker
--- @field host string
--- @field port integer
--- @field delegate UDPChannelDelegate
--- @overload fun(host: string, port: integer, delegate?: UDPChannelDelegate, socket):self
local UDPChannel = {}
local UDPChannelDefaultReceiveSize = 512 * 1024

--- @class UDPChannelDelegate : ChannelDelegate
local UDPChannelDelegate = Object()
UDPChannelDelegate:extends(Channel.Delegate)

local function UDPChannelInitIO(self, host, port, async)
  local io = Socket.UDP()

  if async then
    io:connectNow(host, port)

  else
    io:connect(host, port)
  end

  return io
end

function UDPChannel:new(host, port, delegate, io)
  io = io or UDPChannelInitIO(self, host, port, delegate)
  Channel.new(self, io, delegate)
  EventWorker:add(self, 'r')
end

--- @param size? integer
--- @return string, integer
function UDPChannel:read(size)
  size = size or UDPChannelDefaultReceiveSize

  return self.io:receive(size)
end

--- @param size? integer
--- @return string, integer
function UDPChannel:readNow(size)
  size = size or UDPChannelDefaultReceiveSize

  return self.io:receiveNow(size)
end

function UDPChannel:readAsync()
  if self.delegate and #self.buffer.i > 0 then
    local len = self.delegate:onRead(self, self.buffer.i)
    self:decrease('i', type(len) == 'number' and len or 0)
    return
  end
end

--- @param buffer string
--- @param size? integer
--- @return integer, integer
function UDPChannel:write(buffer, size)
  if not buffer then
    return 0, 0
  end

  size = size or buffer:len()

  return self.io:send(buffer, size)
end

--- @param buffer string
--- @param size? integer
--- @return integer, integer
function UDPChannel:writeNow(buffer, size)
  if not buffer then
    return 0, 0
  end

  size = size or buffer:len()

  return self.io:sendNow(buffer, size)
end

--- @param buffer string
--- @param size? integer
function UDPChannel:writeAsync(buffer, size)
  if buffer then
    if size then
      buffer = buffer:sub(1, size)
    end

    self:increase('o', buffer)
  end

  EventWorker:add(self, 'w')
end

--- @param event EventWorker
--- @return integer
function UDPChannel:onReadEvent(event)
  -- Log:debug('UDPChannel:onReadEvent', tostring(self))
  self.active = os.time()

  local data, err = self:readNow()

  if err == Socket.OK then
    self:increase('i', data)
    if self.delegate then
      local len = self.delegate:onRead(self, self.buffer.i)
      self:decrease('i', type(len) == 'number' and len or 0)
    end

    return EventWorker.Handle.CONTINUE

  elseif err == Socket.Errno.EAGAIN then
    -- UDPChannel read pending
    return EventWorker.Handle.CONTINUE

  elseif err == Socket.Errno.EWOULDBLOCK then
    -- UDPChannel read pending
    return EventWorker.Handle.CONTINUE
  end

  self:close()
  return EventWorker.Handle.ERROR
end

--- @param event EventWorker
--- @return integer
function UDPChannel:onWriteEvent(event)
  -- Log:debug('UDPChannel:onWriteEvent', tostring(self))
  self.active = os.time()

  local len, err = self:writeNow(self.buffer.o, #self.buffer.o)

  if err == Socket.OK then
    self:decrease('o', len)

    if self.delegate then
      self.delegate:onWrite(self, len)
    end

    if #self.buffer.o == 0 then
      return EventWorker.Handle.DONE
    end

    return EventWorker.Handle.CONTINUE

  elseif err == Socket.Errno.EAGAIN then
    -- UDPChannel write pending
    return EventWorker.Handle.CONTINUE

  elseif err == Socket.Errno.EWOULDBLOCK then
    -- UDPChannel write pending
    return EventWorker.Handle.CONTINUE
  end

  self:close()
  return EventWorker.Handle.ERROR
end

function UDPChannel:getAddress()
  return self.io:getAddress()
end

function UDPChannel:shutdown(how)
  if how == 0 then
    EventWorker:remove(self, 'r')

  elseif how == 1 then
    EventWorker:remove(self, 'w')

  elseif how == 2 then
    EventWorker:remove(self, 'a')
  end

  self.io:shutdown(how)
end

function UDPChannel:isClosed()
  return self.io:isClosed()
end

function UDPChannel:isShutdown()
  return self.io:isShutdown()
end

Object(Channel, UDPChannel)
UDPChannel:extends(EventWorker)
UDPChannel.Delegate = UDPChannelDelegate

return UDPChannel
