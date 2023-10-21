--- Light.lua
--- If I were the shore, bright & magnanimous.
--- @author Jakit Liang 泊凛
--- @date 2023-10-20
--- @license BSD 2-Clause License

local Object = require('light.Object')

--- @class Vector2 : Object
local Vector2 = {}

function Vector2:new(x, y)
  rawset(self, 1, x)
  rawset(self, 2, y)
end

function Vector2:getX(offset)
  if offset then
    return rawget(self, 1 + offset)
  end

  return rawget(self, 1)
end

function Vector2:getY(offset)
  if offset then
    return rawget(self, 2 + offset)
  end

  return rawget(self, 2)
end

function Vector2:getVector2(offset)
  if offset then
    return rawget(self, 1 + offset), rawget(self, 2 + offset)
  end

  return rawget(self, 1), rawget(self, 2)
end

function Vector2:setX(x, offset)
  if offset then
    rawset(self, 1 + offset, x)
    return
  end

  rawset(self, 1, x)
end

function Vector2:setY(y, offset)
  if offset then
    rawset(self, 2 + offset, y)
    return
  end

  rawset(self, 2, y)
end

function Vector2:setVector2(x, y, offset)
  if offset then
    rawset(self, 1 + offset, x)
    rawset(self, 2 + offset, y)
    return
  end

  rawset(self, 1, x)
  rawset(self, 2, y)
end

function Vector2:isEqual(v1, v2)
  return rawget(v1, 1) == rawget(v2, 1) and rawget(v1, 2) == rawget(v2, 2)
end

function Vector2:isEqualOffset(v1, offset, v2, offset)
  return rawget(v1, 1 + offset) == rawget(v2, 1 + offset)
  and rawget(v1, 2 + offset) == rawget(v2, 2 + offset)
end

Object(Vector2)

return Vector2
