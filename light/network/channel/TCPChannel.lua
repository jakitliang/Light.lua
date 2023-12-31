--- Light.lua
--- If I were the shore, bright & magnanimous.
--- @module 'TCPChannel'
--- @author Jakit Liang 泊凛
--- @date 2023-10-16
--- @license MIT

local Light = require('Light')
local Object = require('light.Object')
local socket = require('light.socket')
local Channel = require('light.network.Channel')
local EventWorker = require('light.worker.EventWorker')
local Log = require('light.Log')

--- TCPChannel is used to create TCP socket connection<br>
--- Default is blocking. For async usage should have delegate given
--- @class TCPChannel : Channel, EventWorker
--- @field host string
--- @field port integer
--- @field delegate TCPChannelDelegate
--- @overload fun(host: string, port: integer, delegate?: TCPChannelDelegate, socket):self
local TCPChannel = {}
local TCPChannelDefaultReceiveSize = Light.network.DEFAULT_BUFFER_SIZE

--- @class TCPChannelDelegate : ChannelDelegate
local TCPChannelDelegate = Object()
TCPChannelDelegate:extends(Channel.Delegate)

local function TCPChannelInitIO(self, host, port, async)
  local io = socket.TCP()

  if async then
    io:connectNow(host, port)

  else
    io:connect(host, port)
  end

  return io
end

function TCPChannel:new(host, port, delegate, io)
  io = io or TCPChannelInitIO(self, host, port, delegate)
  Channel.new(self, io, delegate)
  EventWorker:add(self, 'r')
end

--- @param size? integer
--- @return string, integer
function TCPChannel:read(size)
  size = size or TCPChannelDefaultReceiveSize

  return self.io:receive(size)
end

--- @param size? integer
--- @return string, integer
function TCPChannel:readNow(size)
  size = size or TCPChannelDefaultReceiveSize

  return self.io:receiveNow(size)
end

function TCPChannel:readAsync()
  if self.delegate and #self.buffer.i > 0 then
    local len = self.delegate:onRead(self, self.buffer.i)
    self:decrease('i', type(len) == 'number' and len or 0)
    return
  end
end

--- @param buffer string
--- @param size? integer
--- @return integer, integer
function TCPChannel:write(buffer, size)
  if not buffer then
    return 0, 0
  end

  size = size or buffer:len()

  return self.io:send(buffer, size)
end

--- @param buffer string
--- @param size? integer
--- @return integer, integer
function TCPChannel:writeNow(buffer, size)
  if not buffer then
    return 0, 0
  end

  size = size or buffer:len()

  return self.io:sendNow(buffer, size)
end

--- @param buffer string
--- @param size? integer
function TCPChannel:writeAsync(buffer, size)
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
function TCPChannel:onReadEvent(event)
  -- Log:debug('TCPChannel:onReadEvent', tostring(self))
  self.active = os.time()

  local data, err = self:readNow()

  if err == socket.OK then
    self:increase('i', data)
    local len = 0
    local buffer = self.buffer

    if self.delegate then
      repeat
        len = self.delegate:onRead(self, buffer.i)
        self:decrease('i', len)

        if #buffer.i == 0 then
          break
        end

      until len == 0
    end

    return EventWorker.Handle.CONTINUE

  elseif err == socket.Errno.EAGAIN then
    -- TCPChannel read pending
    return EventWorker.Handle.CONTINUE

  elseif err == socket.Errno.EWOULDBLOCK then
    -- TCPChannel read pending
    return EventWorker.Handle.CONTINUE
  end

  self:close()
  return EventWorker.Handle.ERROR
end

--- @param event EventWorker
--- @return integer
function TCPChannel:onWriteEvent(event)
  -- Log:debug('TCPChannel:onWriteEvent', tostring(self))
  self.active = os.time()

  local len, err = self:writeNow(self.buffer.o, #self.buffer.o)

  if err == socket.OK then
    self:decrease('o', len)

    if self.delegate then
      self.delegate:onWrite(self, len)
    end

    if #self.buffer.o == 0 then
      return EventWorker.Handle.DONE
    end

    return EventWorker.Handle.CONTINUE

  elseif err == socket.Errno.EAGAIN then
    -- TCPChannel write pending
    return EventWorker.Handle.CONTINUE

  elseif err == socket.Errno.EWOULDBLOCK then
    -- TCPChannel write pending
    return EventWorker.Handle.CONTINUE
  end

  self:close()
  return EventWorker.Handle.ERROR
end

function TCPChannel:getAddress()
  return self.io:getAddress()
end

function TCPChannel:shutdown(how)
  if how == 0 then
    EventWorker:remove(self, 'r')

  elseif how == 1 then
    EventWorker:remove(self, 'w')

  elseif how == 2 then
    EventWorker:remove(self, 'a')
  end

  self.io:shutdown(how)
end

function TCPChannel:isClosed()
  return self.io:isClosed()
end

function TCPChannel:isShutdown()
  return self.io:isShutdown()
end

rawset(TCPChannel --[[@as table]], 'getDefaultReceiveSize', getDefaultReceiveSize)
rawset(TCPChannel --[[@as table]], 'setDefaultReceiveSize', setDefaultReceiveSize)

Object(Channel, TCPChannel)
TCPChannel:extends(EventWorker)
TCPChannel.Delegate = TCPChannelDelegate

return TCPChannel
