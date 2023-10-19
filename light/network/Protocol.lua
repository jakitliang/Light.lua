--- Light.lua
--- Light up your way to the internet
--- @module 'Protocol'
--- @author Jakit Liang 泊凛
--- @date 2023-09-16
--- @license MIT

local Object = require('light.Object')

local ParseStatus = {
  ERROR = -1,
  BEGIN = 0,
  CONTINUE = 0,
  PENDING = 1,
  COMPLETE = 2
}

--- @class Protocol : Object
--- @field offset integer
--- @field status integer
--- @field state integer
local Protocol = {}

function Protocol:new()
  self.status = ParseStatus.BEGIN
  self.offset = 1
end

function Protocol:onPack()
  return ''
end

--- @param source string
--- @return integer
function Protocol:onUnpack(source)
  return ParseStatus.ERROR
end

--- Parse packet
--- @param source string
--- @return integer status, integer offset Parse result and number of bytes
function Protocol:unpack(source)
  local status = ParseStatus.CONTINUE

  while status == ParseStatus.CONTINUE do
    status = self:onUnpack(source)
  end

  if status == ParseStatus.PENDING then
    status = ParseStatus.CONTINUE
  end

  local offset = self.offset - 1
  self.status = status
  self.offset = 1

  return self.status, offset
end

--- @return string
function Protocol:pack()
  return self:onPack()
end

Object(Protocol)

Protocol.ParseStatus = ParseStatus

return Protocol
