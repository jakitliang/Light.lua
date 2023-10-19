--- Record.lua
--- Simplefy Your CRUD Life!
--- @module 'SQLiteDevice'
--- @author Jakit Liang 泊凛
--- @date 2023-09-16
--- @license MIT

local Object = require('light.Object')
local Device = require('light.record.Device')
local SQLite = require('lsqlite3')

local SQLiteDevice = Object(Device)

function SQLiteDevice:new(file)
  self.db = file and SQLite.open(file) or SQLite.open_memory()
  if file then
    self.db:exec("PRAGMA journal_mode=WAL;")
  end
end

function SQLiteDevice:lastId()
  return self.db:last_insert_rowid()
end

function SQLiteDevice:exec(sql)
  return self.db:exec(sql) == SQLite.OK
end

function SQLiteDevice:fetch(sql)
  return self.db:nrows(sql)
end

function SQLiteDevice:begin()
  return self.db:exec('BEGIN;') == SQLite.OK
end

function SQLiteDevice:rollback()
  return self.db:exec('ROLLBACK;') == SQLite.OK
end

function SQLiteDevice:commit()
  return self.db:exec('COMMIT;') == SQLite.OK
end

return SQLiteDevice
