--- Light.lua
--- Light up your way to the internet
--- @module 'Channel'
--- @author Jakit Liang 泊凛
--- @date 2023-09-16
--- @license MIT

local Object = require('light.Object')
local EventWorker = require('light.worker.EventWorker')
local Log = require('light.Log')

--- @class Channel : EventWorkerDelegate
--- @field io any
--- @field buffer {i: string, o:string}
--- @field active integer
--- @field delegate ChannelDelegate
--- @field Delegate ChannelDelegate
--- @overload fun(io, delegate):self
local Channel = {}

--- @class ChannelDelegate : Object
local ChannelDelegate = {}

--- @param channel Channel
--- @param buffer string
--- @return integer
function ChannelDelegate:onRead(channel, buffer)
  return 0
end

--- @param channel Channel
--- @param size integer
function ChannelDelegate:onWrite(channel, size) end

--- @param channel Channel
function ChannelDelegate:onClose(channel) end

Object(ChannelDelegate)

--- @param delegate ChannelDelegate
function Channel:new(io, delegate)
  self.io, self.delegate = io, delegate
  self.buffer = {
    i = '',
    o = ''
  }
  self.active = os.time()
end

function Channel:open() end

function Channel:close()
  -- Log:debug('Channel:close')
  self.io:close()

  if self.delegate then
    self.delegate:onClose(self)
  end

  EventWorker:remove(self, 'a')
end

--- @param size? integer
--- @return string data, integer err
function Channel:read(size)
  return '', 0
end

--- @param buffer string
--- @param size? integer
--- @return integer size, integer err
function Channel:write(buffer, size)
  return 0, 0
end

--- @alias target
--- | '"i"'
--- | '"o"'

--- @param target target
--- @param buffer string
function Channel:increase(target, buffer)
  self.buffer[target] = self.buffer[target] .. buffer
end

--- @param target target
--- @param size integer
function Channel:decrease(target, size)
  if size <= 0 then
    return
  end
  local buffer = self.buffer[target]
  local len = #buffer

  if size >= len then
    self.buffer[target] = ''
    return
  end

  self.buffer[target] = buffer:sub(size + 1, len)
end

Object(Channel)
Channel:extends(EventWorker.Delegate)
Channel.Delegate = ChannelDelegate

return Channel
