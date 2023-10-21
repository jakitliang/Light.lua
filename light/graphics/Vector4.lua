--- Light.lua
--- If I were the shore, bright & magnanimous.
--- @author Jakit Liang 泊凛
--- @date 2023-10-20
--- @license BSD 2-Clause License

local Object = require('light.Object')

--- @class Vector4 : Object
local Vector4 = {}

function Vector4:new(x, y, z, w)
  rawset(self, 1, x)
  rawset(self, 2, y)
  rawset(self, 3, z)
  rawset(self, 4, w)
end

function Vector4:getX(offset)
  if offset then
    return rawget(self, 1 + offset)
  end

  return rawget(self, 1)
end

function Vector4:getY(offset)
  if offset then
    return rawget(self, 2 + offset)
  end

  return rawget(self, 2)
end

function Vector4:getZ(offset)
  if offset then
    return rawget(self, 3 + offset)
  end

  return rawget(self, 3)
end

function Vector4:getW(offset)
  if offset then
    return rawget(self, 4 + offset)
  end

  return rawget(self, 4)
end

function Vector4:getVector4(offset)
  if offset then
    return rawget(self, 1 + offset), rawget(self, 2 + offset),
    rawget(self, 3 + offset), rawget(self, 4 + offset)
  end

  return rawget(self, 1), rawget(self, 2),
  rawget(self, 3), rawget(self, 4)
end

function Vector4:setX(x, offset)
  if offset then
    rawset(self, 1 + offset, x)
    return
  end

  rawset(self, 1, x)
end

function Vector4:setY(y, offset)
  if offset then
    rawset(self, 2 + offset, y)
    return
  end

  rawset(self, 2, y)
end

function Vector4:setZ(z, offset)
  if offset then
    rawset(self, 3 + offset, z)
    return
  end

  rawset(self, 3, z)
end

function Vector4:setW(w, offset)
  if offset then
    rawset(self, 4 + offset, w)
    return
  end

  rawset(self, 4, w)
end

function Vector4:setVector4(x, y, z, w, offset)
  if offset then
    rawset(self, 1 + offset, x)
    rawset(self, 2 + offset, y)
    rawset(self, 3 + offset, z)
    rawset(self, 4 + offset, w)
    return
  end

  rawset(self, 1, x)
  rawset(self, 2, y)
  rawset(self, 3, z)
  rawset(self, 4, w)
end

function Vector4:isEqual(v1, v2)
  return rawget(v1, 1) == rawget(v2, 1)
  and rawget(v1, 2) == rawget(v2, 2)
  and rawget(v1, 3) == rawget(v2, 3)
  and rawget(v1, 4) == rawget(v2, 4)
end

function Vector4:isEqualOffset(v1, offset, v2, offset)
  return rawget(v1, 1 + offset) == rawget(v2, 1 + offset)
  and rawget(v1, 2 + offset) == rawget(v2, 2 + offset)
  and rawget(v1, 3 + offset) == rawget(v2, 3 + offset)
  and rawget(v1, 4 + offset) == rawget(v2, 4 + offset)
end

Object(Vector4)

return Vector4
