--- Light.lua
--- Light up your way to the internet
--- @module 'Log'
--- @author Jakit Liang 泊凛
--- @date 2023-10-16
--- @license MIT

local Object = require('light.Object')

local LogLevel = {
  INFO = 1,
  WARNING = 2,
  ERROR = 3,
  DEBUG = 4
}

local LogLevelMessage = {
  '[INFO]',
  '[WARN]',
  '[ERRO]',
  '[DEBG]'
}

local Log = {level = LogLevel.INFO, io = io}
local message

function Log:info(...)
  self:print(LogLevel.INFO, ...)
end

function Log:infoF(format, ...)
  self:print(LogLevel.INFO, string.format(format, ...))
end

function Log:warning(...)
  self:print(LogLevel.WARNING, ...)
end

function Log:warningF(format, ...)
  self:print(LogLevel.WARNING, string.format(format, ...))
end

function Log:error(...)
  self:print(LogLevel.ERROR, ...)
end

function Log:errorF(format, ...)
  self:print(LogLevel.ERROR, string.format(format, ...))
end

function Log:debug(...)
  self:print(LogLevel.DEBUG, ...)
end

function Log:debugF(format, ...)
  self:print(LogLevel.DEBUG, string.format(format, ...))
end

function Log:print(level, ...)
  if self.level >= level then
    message = {LogLevelMessage[level] .. '[' .. os.date("%Y-%m-%d %H:%M:%S") .. ']', ...}
    self.io.write(table.concat(message, ' '), "\n")
  end
end

Object(Log)

Log.Level = LogLevel

return Log
