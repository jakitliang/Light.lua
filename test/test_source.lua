
io.stdout:setvbuf('no')

package.path = "..\\?.lua;" .. "" .. package.path

local inspect = require('inspect')
local Source = require('light.graphics.Source')

local a = {k = Source.Type.INTEGER}
local b = {m = Source.Type.INTEGER}
local c = {n = Source.Type.INTEGER}
local d = {z = Source.Type.INTEGER}
-- Source['a.b'] = Source['a.b'] and Source['a.b'].__fields = b or b
-- Source['a'].__fields = {k = Source.Type.INTEGER}

local sd = Source('a.b.c.d', d)
local sc = Source('a.b.c', c)
local sb = Source('a.b', b)
local sa = Source('a', a)

print(inspect(Source.a))
print(inspect(Source.a.b))

print(inspect(sa))
print(inspect(sb))
print(inspect(sc))
print(inspect(sd))
print(inspect(sb['c.d']))

Source.a.b:setData({
  m = '123',
})

print('------------')
print(inspect(Source.a.b))
