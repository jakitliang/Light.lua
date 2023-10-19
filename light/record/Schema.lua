--- Record.lua
--- Simplefy Your CRUD Life!
--- @module 'Schema'
--- @author Jakit Liang 泊凛
--- @date 2023-09-16
--- @license MIT

local Object = require('light.object')
local Field = require('light.record.field')

--- @class Schema : table
local Schema = Object()

function Schema:new(table, callback)
  self.table = table
  self.fields = {}
  self:integer('id', true, true)
  callback(self)
end

--- @param field string
function Schema:integer(field, primaryKey, autoincrement)
  self[field] = Field(field, Field.integer)
  table.insert(self.fields, self[field])

  if primaryKey then
    self[field].primaryKey = true

    if autoincrement then
      self[field].autoincrement = true
    end
  end
end

--- @param field string
function Schema:real(field)
  self[field] = Field(field, Field.real)
  table.insert(self.fields, self[field])
end

--- @param field string
function Schema:text(field)
  self[field] = Field(field, Field.text)
  table.insert(self.fields, self[field])
end

--- @param field string
function Schema:blob(field)
  self[field] = Field(field, Field.blob)
  table.insert(self.fields, self[field])
end

--- @param field string
function Schema:date(field)
  self[field] = Field(field, Field.datetime)
  table.insert(self.fields, self[field])
end

return Schema
