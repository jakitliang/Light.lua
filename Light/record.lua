--- Record.lua
--- Easy Record Your CRUD Life!
--- @module 'Record'
--- @author Jakit Liang 泊凛
--- @date 2023-09-16
--- @license MIT

local Object = require('core.object')
local Field = require('core.record.field')
local Schema = require('core.record.schema')
local Query = require('core.record.query')

--- Provide Record
--- @class Record : Object
--- @field device Device
--- @field schema Schema
--- @overload fun():self
local Record = {}

function Record:new() end

--- Create table schema if not exists
--- @return boolean status
function Record:create()
  local sql = 'create table if not exists `'..self.schema.table.. "` (\n"
  local lines = {}

  for i = 1, #self.schema.fields do
    local field = self.schema.fields[i]
    local part = '`'..field.name..'` '..field.type
    if field.primaryKey then
      part = part .. ' primary key'

      if field.autoincrement then
        part = part .. ' autoincrement'
      end
    end
    table.insert(lines, part)
  end

  sql = sql .. table.concat(lines, ",\n") .. "\n)"
  return self:query(sql)
end

--- Save a record
--- @return boolean status
function Record:save()
  local query = self:newQuery()
  query:insert()

  if self:query(query) then
    self.id = self.device:lastId()
    return true
  end

  return false
end

--- Fetch records
--- @param limit? integer|table The count and offset of result, eg: 5 or {5, 10}
--- @param order? boolean|table The order of result, eg: false(reverse) or {id, true}
--- @return table result
function Record:fetch(limit, order)
  return self:find(nil, limit, order)
end

--- Fetch one record
--- @return table? result
function Record:fetchOne()
  return self:fetch(1)[1]
end

--- Find records by condition
--- @param condition? table The conditions to filter the result
--- @param limit? integer|table The count and offset of result, eg: 5 or {5, 10}
--- @param order? boolean|string|table The order of result, eg: false(reverse) or {id, true}
--- @return table result
function Record:find(condition, limit, order)
  local query = self:findBy(condition)

  if order then
    query:orderBy(order)
  end

  if type(limit) == 'number' then
    return query:fetch(limit)

  elseif type(limit) == 'table' then
    return query:fetch(limit[1], limit[2])
  end

  return query:fetchAll()
end

--- Find records by condition
--- @param condition? table The conditions to filter the result
--- @param order? boolean|string|table The order of result, eg: false(reverse) or {id, true}
--- @return table? result
function Record:findOne(condition, order)
  return self:find(condition, 1, order)[1]
end

--- Find records by condition
--- @param condition? table The conditions to filter the result
--- @return Query query
function Record:findBy(condition)
  local query = self:newQuery()

  if condition then
    query:where(condition)
  end

  return query
end

--- Update a record
--- @return boolean status
function Record:update()
  local query = self:newQuery()
  query:where({'id', self.id})
  query:update()
  return self:query(query)
end

--- Destroy a record or delete records by condition
--- @return boolean status
function Record:destroy(condition)
  local query = self:newQuery()

  if condition then
    query:where(condition)

  elseif self.id then
    query:where({'id', self.id})
  end

  query:delete()
  return self:query(query)
end

function Record:count(condition)
  if condition then
    return self:findBy(condition):count()
  end

  return self:newQuery():count()
end

--- Execute a query
--- @return boolean status
function Record:query(query)
  if type(query) == 'string' then
    local sql = query
    query = self:newQuery()
    query.sql = sql
  end

  Record.lastQuery = query
  return query:exec()
end

--- Create a new query
--- @return Query
function Record:newQuery()
  return Query(self)
end

--- Transaction begin
--- @return boolean status
function Record:begin()
  return self.device:begin()
end

--- Transaction rollback and finished
--- @return boolean status
function Record:rollback()
  return self.device:rollback()
end

--- Transaction commit and finished
--- @return boolean status
function Record:commit()
  return self.device:commit()
end

function Record:transaction(callback)
  local ok = true
  self:begin()
  callback(function ()
    ok = false
    self:rollback()
  end)
  if ok then
    self:commit()
  end
end

Object(Record)

return Record
