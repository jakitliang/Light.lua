--- Record.lua
--- Simplefy Your CRUD Life!
--- @module 'Device'
--- @author Jakit Liang 泊凛
--- @date 2023-09-16
--- @license MIT

local Object = require('light.object')

--- @class Device
local Device = Object()

function Device:new() end

function Device:lastId()
  return - 1
end

function Device:exec(sql)
  return false
end

function Device:fetch(sql)
  return nil
end

function Device:begin()
  return false
end

function Device:rollback()
  return false
end

function Device:commit()
  return false
end

return Device
