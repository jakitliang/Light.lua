--- Object.lua
--- Enjoy Objective Coding!
--- Prototype based and elastic util
--- @author Jakit Liang 泊凛
--- @date 2023-10-12
--- @license MIT

--- <b>Create new object and inherit from prototype:</b> <br>
--- 1. Object() # Create new object <br>
--- 2. Object({...}) # Init as object with table {...} already exists <br>
--- 3. Object(proto); # Create object and inherit from proto <br>
--- 4. Object(proto, {...}); # Create object with table {...} and inherit from proto
--- @class Object
--- @overload fun(proto: table|Object|function, table: table|function|Object):any
--- @overload fun(proto: table|function|Object):any
--- @overload fun(table: table):any
--- @overload fun():any
local Object = {}

--- Constructor of the object
function Object:new()
  -- fallback call
end

--- Check whether the object is prototype of the specified one
function Object:instanceOf(proto)
  local __proto = rawget(self, '__proto')

  while __proto do
    if __proto == proto then
      return true
    end

    __proto = rawget(__proto, '__proto')
  end

  return false
end

function Object:getProto()
  return rawget(self, '__proto')
end

--- Extends the methods from another object
function Object:extends(object)
  for k, v in pairs(object) do
    if string.find(k, '__') or k == 'new' then
      goto continue
    end

    if not self[k] then
      rawset(self, k, rawget(object, k))
    end

    ::continue::
  end

  return self
end

--- Clone the object
--- @generic T
--- @param self T
--- @return T
function Object.clone(self)
  local object = {}

  for k, v in pairs(self) do
    rawset(object, k, v)
  end

  return setmetatable(object, getmetatable(self))
end

local ObjectMetatable = {__cache = false}

function ObjectMetatable.__index(self, key, check)
  if self == Object then
    -- not found
    return nil
  end

  check = not check and type(key) == 'string' and 'get' .. key:sub(1, 1):upper() .. key:sub(2)
  local proto = self
  local __index, get, ret = nil, nil, nil
  local __cache = ObjectMetatable.__cache

  while proto do
    __index = rawget(proto, '__index')

    if __index then
      if __cache then
        rawset(self, '__index', __index)
      end

      ret = __index(self, key)

      if ret then
        break
      end
    end

    ret = rawget(proto, key)

    if ret then
      if __cache and type(ret) == 'function' then
        rawset(self, key, ret)
      end

      break
    end

    get = check and rawget(proto, check)

    if get then
      if __cache then
        rawset(self, check, get)
      end

      return get(self)
    end

    proto = rawget(proto, '__proto')
  end

  return ret
end

function ObjectMetatable.__call(self, ...)
  if self == Object then
    local proto, object = ...

    if proto then
      if not rawget(proto, '__proto') then
        proto, object = Object, proto
      end

      object = object or {}
      --- @diagnostic disable-next-line: param-type-mismatch
      rawset(object, '__proto', proto)
      --- @diagnostic disable-next-line: param-type-mismatch
      setmetatable(object, ObjectMetatable)
      return object
    end
  end

  local constructor = self.new
  local object = {__proto = self}

  setmetatable(object, ObjectMetatable)
  constructor(object, ...)
  return object
end

function ObjectMetatable.__newindex(self, key, value)
  if self == Object then
    -- do not edit Object it self
    return
  end

  local check = type(key) == 'string' and 'set' .. key:sub(1, 1):upper() .. key:sub(2)
  local proto = self
  local __newindex, set, ret = nil, nil, nil
  local __cache = ObjectMetatable.__cache

  while proto do
    __newindex = rawget(proto, '__newindex')

    if __newindex then
      return __newindex(self, key, value)
    end

    set = check and rawget(proto, check)

    if set then
      return set(self, value)
    end

    proto = rawget(proto, '__proto')
  end

  rawset(self, key, value)
end

function ObjectMetatable.__add(op1, op2)
  local __add = ObjectMetatable.__index(op1, '__add', true)

  return __add and __add(op1, op2)
end

function ObjectMetatable.__sub(op1, op2)
  local __sub = ObjectMetatable.__index(op1, '__sub', true)

  return __sub and __sub(op1, op2)
end

function ObjectMetatable.__mul(op1, op2)
  local __mul = ObjectMetatable.__index(op1, '__mul', true)

  return __mul and __mul(op1, op2)
end

function ObjectMetatable.__div(op1, op2)
  local __div = ObjectMetatable.__index(op1, '__div', true)

  return __div and __div(op1, op2)
end

function ObjectMetatable.__concat(op1, op2)
  local __concat = ObjectMetatable.__index(op1, '__concat', true)

  return __concat and __concat(op1, op2)
end

function ObjectMetatable.__pairs(self)
  return ObjectMetatable.__index(self, '__pairs', true) or next, self, nil
end

function ObjectMetatable:__tostring()
  local proto = rawget(self, '__proto')
  local __tostring = nil

  while proto do
    __tostring = rawget(proto, '__tostring')

    if __tostring then
      return __tostring(self)
    end

    proto = rawget(proto, '__proto')
  end

  return string.format('Object: %p', self)
end

function Object:setMethodCache(mode)
  if mode then
    rawset(ObjectMetatable, '__cache', true)
  end

  rawset(ObjectMetatable, '__cache', false)
end

--- @diagnostic disable-next-line: param-type-mismatch
setmetatable(Object, ObjectMetatable)

return Object
