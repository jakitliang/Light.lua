--- Light.lua
--- Light up your way to the internet
--- @module 'Worker'
--- @author Jakit Liang 泊凛
--- @date 2023-09-16
--- @license MIT

local Object = require('light.Object')
local socket = require('light.socket')

--- @class Worker : Object
local Worker = {}

local function runLoop(self)
  return function (...)
    while self.isRunning do
      coroutine.yield(self:handle(...))
    end
  end
end

function Worker:new()
  self.isRunning = false
  self.runLoop = coroutine.create(runLoop(self))
end

function Worker:join()
  local count = 0
  while self.isRunning and count < 1000 do
    socket.Select(nil, nil, 0.05)
  end
end

function Worker:resume()
  self.isRunning = true
  local ret = coroutine.resume(self.runLoop)
  self.isRunning = false

  return ret
end

function Worker:handle(...) end

Object(Worker)

return Worker
