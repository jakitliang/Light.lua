--- Light.lua
--- Light up your way to the internet
--- @module 'Session'
--- @author Jakit Liang 泊凛
--- @date 2023-09-16
--- @license MIT

local Object = require('core.object')
local EventWorker = require('core.worker.event_worker')
local Log = require('core.log')

--- @class Session : Object
--- @field channel Channel
--- @field queue integer[]
local Session = {}

--- @param channel Channel
function Session:new(channel)
  self.channel = channel
  self.queue = {}
end

function Session:enqueue(size)
  table.insert(self.queue, size)
end

function Session:dequeue(size)
  local queue = self.queue
  local top = queue[1]
  local count = 0

  while size > 0 do
    if size > top then
      size = size - top
      table.remove(queue, 1)
      count = count + 1

    elseif size == top then
      table.remove(queue, 1)
      count = count + 1
      break

    else
      queue[1] = top - size
      break
    end
  end

  self:completion(count)
end

function Session:completion(count)
  -- Log:debug('Session:completion', count)
end

function Session:close()
  self.channel:close()
end

function Session:resume()
  EventWorker:resume()
end

Object(Session)

return Session
