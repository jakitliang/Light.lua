--- Record.lua
--- Simplefy Your CRUD Life!
--- @module 'Field'
--- @author Jakit Liang 泊凛
--- @date 2023-09-16
--- @license MIT

local Object = require('light.Object')

--- @class Field
--- @field integer string
--- @field real string
--- @field text string
--- @field blob string
--- @field datetime string
local Field = {
  integer = 'integer',
  real = 'real',
  text = 'text',
  blob = 'blob',
  datetime = 'datetime'
}

function Field:new(name, type)
  self.name = name
  self.type = type
  self.primaryKey = false
  self.autoincrement = false
end

Object(Field)

return Field
