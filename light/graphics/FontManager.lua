--- Light.lua
--- If I were the shore, bright & magnanimous.
--- @author Jakit Liang 泊凛
--- @date 2023-10-20
--- @license BSD 2-Clause License

local Object = require("light.Object")

--- @class Font : Object
--- @field [integer] love.Font
--- @field font love.Font
--- @overload fun(file:string):Font
local Font = {DefaultSize = 12}

local function loadFont(self, file, size)
  local font = love.graphics.newFont(file, size)
  rawset(self, size, font)
  return font
end

function Font:__index(size)
  local font = rawget(self, size)
  local file = rawget(self, 'file')

  if not font then
    font = loadFont(self, file, size)
  end

  return font
end

function Font:new(file)
  self.file = love.filesystem.newFileData(file)
  Font.__index(self, Font.DefaultSize)
end

function Font:getFont()
  return Font.__index(self, Font.DefaultSize)
end

Object(Font)

--- @class FontManager : Object
--- @field [string] Font
local FontManager = {}

function FontManager:__index(name)
  return rawget(self, name)
end

function FontManager:__newindex(name, file)
  local font = Font(file)
  rawset(self, name, font)
end

function FontManager:setDefaultSize(size)
  if type(size) == 'number' then
    Font.DefaultSize = size
  end
end

Object(FontManager)

return FontManager
