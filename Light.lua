--- Light.lua
--- If I were the shore, bright & magnanimous.
--- @module 'Light'
--- @author Jakit Liang 泊凛
--- @date 2023-10-16
--- @license MIT

local Object = require('light.Object')
local Light = {
  network = {
    DEFAULT_BUFFER_SIZE = 2 * 1024 * 1024 -- 2 MB
  },
}

Object(Light)
return Light
