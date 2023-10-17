--- Record.lua
--- Simplefy Your CRUD Life!
--- @module 'Query'
--- @author Jakit Liang 泊凛
--- @date 2023-09-16
--- @license MIT

local Object = require('light.object')

--- @class Query
--- @field table string
--- @field condition table
--- @field order string|nil
--- @field sql string
local Query = Object()

function Query:new(record)
  self.record = record
  self.condition = {}
  self.order = nil
  self.sql = ''
end

local function parseWhere(condition)
  if type(condition) == 'string' then
    return condition
  end

  local statement = '`'..condition[1] .. '` '

  if type(condition[2]) == 'table' then
    if condition[2][1] == 'in' then
      if type(condition[2][2]) ~= 'table' then
        return nil
      end

      statement = statement .. "in ('" .. table.concat(condition[2][2], "', '") .. "')"
      return statement
    end

    statement = statement .. condition[2][1] .. " '"..condition[2][2] .. "'"
    return statement
  end

  statement = statement .. " = '" .. condition[2] .. "'"
  return statement
end

function Query:where(condition, isOr)
  if type(condition) == 'table' then
    for k, v in pairs(condition) do
      if type(k) == 'string' then
        self:where({k, v}, isOr)
      end
    end
  end

  if #condition == 0 then
    return self
  end

  if #self.condition > 0 then
    if isOr then
      table.insert(self.condition, 'or')

    else
      table.insert(self.condition, 'and')
    end
  end

  if #condition == 0 then
    return self
  end

  local statement = parseWhere(condition)

  if statement then
    table.insert(self.condition, statement)
  end

  return self
end

function Query:orWhere(condition)
  return self:where(condition, true)
end

function Query:orderBy(order, reversed)
  if type(order) == 'table' then
    self.order = 'order by `' .. order[1] .. '` '

    if order[2] then
      self.order = self.order .. 'desc'

    else
      self.order = self.order .. 'asc'
    end

  elseif type(order) == 'boolean' then
    self.order = 'order by id desc'

  elseif type(order) == 'string' then
    self.order = 'order by `' .. order .. '`'

    if reversed then
      self.order = self.order .. ' desc'
    end
  end

  return self
end

function Query:parseRow(row)
  local record, field = self.record()
  local fields = record.schema.fields

  for i = 1, #fields do
    if row[fields[i].name] then
      record[fields[i].name] = row[fields[i].name]
    end
  end

  return record
end

function Query:count()
  local sql = 'select count(*) from ' .. self.record.schema.table
  if #self.condition > 0 then
    sql = sql .. ' where ' .. table.concat(self.condition, ' ')
  end
  self.sql = sql

  for row in self.record.device:fetch(self.sql) do
    for k, v in pairs(row) do
      return v
    end
  end

  return 0
end

--- Fetch one result
--- @return table?
function Query:fetchOne()
  return self:fetch(1)[1]
end

--- Fetch all result
--- @return table
function Query:fetchAll()
  return self:fetch()
end

--- Fetch result with setting offset and count
function Query:fetch(from, count)
  local sql = 'select * from ' .. self.record.schema.table

  if #self.condition > 0 then
    sql = sql .. ' where ' .. table.concat(self.condition, ' ')
  end

  if self.order then
    sql = sql .. ' ' .. self.order
  end

  if from then
    sql = sql .. ' limit ' .. from

    if count then
      sql = sql .. ', ' .. count
    end
  end

  self.sql = sql

  -- print(self.sql)

  local records = {}

  for row in self.record.device:fetch(self.sql) do
    table.insert(records, self:parseRow(row))
  end

  return records
end

local function parseValue(record)
  local names, values = {}, {}
  local field

  for i = 1, #record.schema.fields do
    field = record.schema.fields[i]

    if record[field.name] then
      table.insert(names, field.name)
      table.insert(values, "'" .. record[field.name] .. "'")
    end
  end

  return names, values
end

function Query:insert()
  local sql = 'insert into `' .. self.record.schema.table .. "` "
  local names, values = parseValue(self.record)
  sql = sql .. '(`' .. table.concat(names, "`, `") .. '`)'
  sql = sql .. ' values '
  self.sql = sql .. '(' .. table.concat(values, ', ') .. ')'
end

function Query:update()
  local sql = 'update `' .. self.record.schema.table .. '` set '
  local values = {}
  local field

  for i = 1, #self.record.schema.fields do
    field = self.record.schema.fields[i]

    if self.record[field.name] then
      table.insert(values, '`'..field.name.."` = '"..self.record[field.name] .. "'")
    end
  end

  sql = sql .. table.concat(values, ", ")

  if self.condition == 0 then
    return
  end

  self.sql = sql .. ' where ' .. table.concat(self.condition, ' ')
end

function Query:delete()
  local sql = 'delete from `' .. self.record.schema.table .. '` '
  if self.condition == 0 then
    return
  end
  self.sql = sql .. 'where ' .. table.concat(self.condition, ' ')
end

function Query:exec()
  -- print(self.sql)
  return self.record.device:exec(self.sql)
end

return Query
