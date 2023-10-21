--- Light.lua
--- If I were the shore, bright & magnanimous.
--- @author Jakit Liang 泊凛
--- @date 2023-10-20
--- @license BSD 2-Clause License

local Object = require('light.Object')

--- @class Vector3 : Object
local Vector3 = {}

function Vector3:new(x, y, z)
  rawset(self, 1, x)
  rawset(self, 2, y)
  rawset(self, 3, z)
end

function Vector3:getX(offset)
  if offset then
    return rawget(self, 1 + offset)
  end

  return rawget(self, 1)
end

function Vector3:getY(offset)
  if offset then
    return rawget(self, 2 + offset)
  end

  return rawget(self, 2)
end

function Vector3:getZ(offset)
  if offset then
    return rawget(self, 3 + offset)
  end

  return rawget(self, 3)
end

function Vector3:getVector3(offset)
  if offset then
    return rawget(self, 1 + offset), rawget(self, 2 + offset), rawget(self, 3 + offset)
  end

  return rawget(self, 1), rawget(self, 2), rawget(self, 3)
end

function Vector3:setX(x, offset)
  if offset then
    rawset(self, 1 + offset, x)
    return
  end

  rawset(self, 1, x)
end

function Vector3:setY(y, offset)
  if offset then
    rawset(self, 2 + offset, y)
    return
  end

  rawset(self, 2, y)
end

function Vector3:setZ(z, offset)
  if offset then
    rawset(self, 3 + offset, z)
    return
  end

  rawset(self, 3, z)
end

function Vector3:setVector3(x, y, z, offset)
  if offset then
    rawset(self, 1 + offset, x)
    rawset(self, 2 + offset, y)
    rawset(self, 3 + offset, z)
    return
  end

  rawset(self, 1, x)
  rawset(self, 2, y)
  rawset(self, 3, z)
end

function Vector3:isEqual(v1, v2)
  return rawget(v1, 1) == rawget(v2, 1)
  and rawget(v1, 2) == rawget(v2, 2)
  and rawget(v1, 3) == rawget(v2, 3)
end

function Vector3:isEqualOffset(v1, offset, v2, offset)
  return rawget(v1, 1 + offset) == rawget(v2, 1 + offset)
  and rawget(v1, 2 + offset) == rawget(v2, 2 + offset)
  and rawget(v1, 3 + offset) == rawget(v2, 3 + offset)
end

Object(Vector3)

return Vector3
