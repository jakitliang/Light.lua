--- Light.lua
--- Light up your way to the internet
--- @module 'EventWorker'
--- @author Jakit Liang 泊凛
--- @date 2023-09-16
--- @license MIT

local Object = require('light.object')
local Socket = require('light.socket')
local Worker = require('light.worker')
local Log = require('light.log')
local band, bor, bxor, bnot = bit.band, bit.bor, bit.bxor, bit.bnot

local EVENT_WORKER_DEFAULT_STEP = 5

--- @class EventWorker : Worker
--- @field step number
--- @field channels table<any, {channel:Channel, mode:integer}>
--- @overload fun(step: number):self
local EventWorker = {}

local EventWorkerFlag = {
  READ = 1,
  WRITE = 2
}

local EventWorkerHandle = {
  ERROR = -1,
  CONTINUE = 0,
  DONE = 1,
}

--- @class EventWorkerDelegate : Object
local EventWorkerDelegate = Object()

--- @param event EventWorker
--- @return boolean
function EventWorkerDelegate:onReadEvent(event)
  return true
end

--- @param event EventWorker
--- @return boolean
function EventWorkerDelegate:onWriteEvent(event)
  return true
end

--- @param channels table<any, {channel:Channel, mode:integer}>
local function GetChannelIO(channels)
  local readIO, writeIO = {}, {}

  for io, v in pairs(channels) do
    if band(v.mode, EventWorkerFlag.READ) > 0 then
      table.insert(readIO, io)
    end

    if band(v.mode, EventWorkerFlag.WRITE) > 0 then
      table.insert(writeIO, io)
    end
  end

  return readIO, writeIO
end

--- @alias mode
--- | '"r"' Read mode
--- | '"w"' Write mode
--- | '"a"' All mode

--- @param channels table<any, {channel:Channel, mode:integer}>
--- @param channel Channel
--- @param mode mode
local function AddChannel(channels, channel, mode)
  if not channels[channel.io] then
    channels[channel.io] = {channel = channel, mode = 0}
  end

  if mode == 'r' then
    channels[channel.io].mode = bor(channels[channel.io].mode, EventWorkerFlag.READ)

  elseif mode == 'w' then
    channels[channel.io].mode = bor(channels[channel.io].mode, EventWorkerFlag.WRITE)

  elseif mode == 'a' then
    channels[channel.io].mode = bor(channels[channel.io].mode, EventWorkerFlag.READ)
    channels[channel.io].mode = bor(channels[channel.io].mode, EventWorkerFlag.WRITE)
  end
end

--- @param channels table<any, {channel:Channel, mode:integer}>
--- @param channel Channel
--- @param mode mode
local function RemoveChannel(channels, channel, mode)
  if not channels[channel.io] then
    return
  end

  if mode == 'r' then
    channels[channel.io].mode = band(channels[channel.io].mode, bnot(EventWorkerFlag.READ))

  elseif mode == 'w' then
    channels[channel.io].mode = band(channels[channel.io].mode, bnot(EventWorkerFlag.WRITE))

  elseif mode == 'a' then
    channels[channel.io].mode = band(channels[channel.io].mode, bnot(EventWorkerFlag.READ))
    channels[channel.io].mode = band(channels[channel.io].mode, bnot(EventWorkerFlag.WRITE))
  end

  if channels[channel.io].mode == 0 then
    channels[channel.io] = nil
  end
end

--- @param step number
function EventWorker:new(step)
  Worker.new(self)
  self.step = step
  self.channels = {}
end

function EventWorker:handle(...)
  -- Log:debug('======== Channels('..#self.channels..'):setep('..self.step..') =========')
  --- @type any[], any[]
  local readIO, writeIO = GetChannelIO(self.channels)
  local err

  -- Log:debug('r', #readIO)
  -- Log:debug('w', #writeIO)
  --- @type any[], any[], string
  readIO, writeIO, err = Socket.Select(readIO, writeIO, self.step)

  local channel, ret
  for i = 1, #readIO do
    channel = self.channels[readIO[i]].channel
    ret = channel:onReadEvent(self)

    if ret == EventWorkerHandle.DONE then
      self:remove(channel, 'r')

    elseif ret == EventWorkerHandle.ERROR then
      self:remove(channel, 'a')
    end
  end

  for i = 1, #writeIO do
    if self.channels[writeIO[i]] then
      channel = self.channels[writeIO[i]].channel
      ret = channel:onWriteEvent(self)

      if ret == EventWorkerHandle.DONE then
        self:remove(channel, 'w')

      elseif ret == EventWorkerHandle.ERROR then
        self:remove(channel, 'a')
      end
    end
  end
end

--- @param channel Channel
--- @param mode mode
function EventWorker:add(channel, mode)
  AddChannel(self.channels, channel, mode)
end

--- @param channel Channel
--- @param mode mode
function EventWorker:remove(channel, mode)
  RemoveChannel(self.channels, channel, mode)
end

Object(Worker, EventWorker)

EventWorker.Handle = EventWorkerHandle
EventWorker.Delegate = EventWorkerDelegate
EventWorker.Instance = EventWorker(EVENT_WORKER_DEFAULT_STEP)

return EventWorker.Instance
