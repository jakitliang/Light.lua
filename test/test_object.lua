
io.stdout:setvbuf('no')

local Object = require('light.Object')

local Animal = {}

function Animal:getName()
  print('Animal:getName')
  return rawget(self, 'name')
end

function Animal:setName(name)
  print('Animal:setName', name)
  rawset(self, 'name', name)
end

Object(Animal)

Animal.name = 'monkey'
Animal.name = 'bird'

Animal['a.b'] = 123

print(Animal.a.b)

--- @class A
local A = Object()

local s = rawget(A, 's')
rawset(A, 'x', 1)

