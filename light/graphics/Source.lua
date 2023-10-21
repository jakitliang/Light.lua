--- Light.lua
--- If I were the shore, bright & magnanimous.
--- @author Jakit Liang 泊凛
--- @date 2023-10-20
--- @license BSD 2-Clause License

local SourceType = {
  INTEGER = 'integer',
  NUMBER = 'number',
  STRING = 'string'
}

local function split(str, delimiter)
  local ret = {}
  for k, v in string.gmatch(str, "([^" .. delimiter .. "]+)") do
    ret[#ret + 1] = k
  end
  return ret
end

local SourceIndex = {}
local SourceEmptyField = {}

--- @class Source
--- @field [string] Source
local Source = {}

function SourceIndex:__index(key)
  local index = split(key, '.')
  local current = self

  if key == 'setData' then
    return rawget(Source, 'setData')
  end

  for i = 1, #index do
    current = rawget(current, index[i])
    if not current then
      break
    end
  end

  return current
end

function SourceIndex:__newindex(key, value)
  local index = split(key, '.')
  local current = self
  local source

  for i = 1, #index do
    source = rawget(current, index[i])
    if not source then
      rawset(current, index[i], setmetatable({__fields = SourceEmptyField}, SourceIndex))
      source = rawget(current, index[i])
    end
    current = source
  end

  current.__fields = value
end

function Source:setFields()
  local fields = rawget(self, '__fields')
  for key, type in pairs(fields) do
    if type == SourceType.INTEGER then
      rawset(self, key, 0)

    elseif type == SourceType.NUMBER then
      rawset(self, key, 0.0)

    elseif type == SourceType.STRING then
      rawset(self, key, '')
    end
  end
end

--- @param data table<string, any>
function Source:setData(data)
  local fields = rawget(self, '__fields')
  for key, type in pairs(fields) do
    local value = data[key]

    if type == SourceType.INTEGER then
      rawset(self, key, math.floor(tonumber(value or 0) or 0))

    elseif type == SourceType.NUMBER then
      rawset(self, key, tonumber(value or 0) or 0)

    elseif type == SourceType.STRING then
      rawset(self, key, tostring(value or ''))
    end
  end
end

local function __call(self, ...)
  local key, value = ...
  local source = self[key]

  if source then
    source.__fields = value
    Source.setFields(source)
    return source
  end

  self[key] = value
  source = self[key]
  Source.setFields(source)
  return source
end

Source.Type = SourceType

setmetatable(Source, {
  __index = SourceIndex.__index,
  __newindex = SourceIndex.__newindex,
  __call = __call
})

return Source
