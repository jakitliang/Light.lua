--- Light.lua
--- If I were the shore, bright & magnanimous.
--- @author Jakit Liang 泊凛
--- @date 2023-10-20
--- @license BSD 2-Clause License

local Object = require('light.Object')
local Layer = require('light.graphics.Layer')
local FontManager = require('light.graphics.FontManager')

--- @class TextLayer : Layer
--- @field canvas love.Canvas
--- @field font love.Font
--- @field private str string
--- @field private text table
--- @overload fun(x:number, y:number, str?:string, delegate?:LayerDelegate, font?:love.Font):self
local TextLayer = {}

local colorWhite = {1, 1, 1}
local colorRed = {1, 0, 0}
local colorGreen = {0, 1, 0}
local colorBlue = {0, 0, 1}

local canvas = rawget(Layer --[[@as Layer]], 'FallBackCanvas')
local toQuad = rawget(Layer --[[@as Layer]], 'toQuad')

local function ClearText(text)
  for i = 1, #text do
    table.remove(text, i)
  end

  return text
end

--- @param self TextLayer
local function parseLine(self, str)
  local lineCount = 0
  local first, last = 0, 0
  local tmpWidth = 0
  local width, height = 0, 0

  while true do
    first = str:find("\n", first + 1)
    if not first then break end
    tmpWidth = self.font:getWidth(str:sub(last, first - 1))

    if tmpWidth > width then
      width = tmpWidth
    end

    lineCount = lineCount + 1
  end

  if last ~= str:len() then
    tmpWidth = self.font:getWidth(str:sub(last, str:len()))
    if tmpWidth > width then
      width = tmpWidth
    end

    lineCount = lineCount + 1
  end

  height = self.font:getHeight() * lineCount

  return width, height
end

local function parseText(str)
  -- Process text color
  local first, last, tmp = 0, 0, nil
  local txt = {}
  local lastColor = colorWhite

  while true do
    tmp = str:find("#", first + 1)
    if not tmp then break end
    first = tmp

    table.insert(txt, lastColor)
    table.insert(txt, str:sub(last, first - 1))

    last = first + 1
    local color = str:sub(last - 1, last)

    if color == '#R' then
      last = last + 1
      lastColor = colorRed

    elseif color == '#G' then
      last = last + 1
      lastColor = colorGreen

    elseif color == '#B' then
      last = last + 1
      lastColor = colorBlue

    elseif color == '#W' then
      last = last + 1
      lastColor = colorWhite
    end
  end

  if last ~= str:len() then
    table.insert(txt, lastColor)
    table.insert(txt, str:sub(last, str:len()))
  end

  return txt
end

function TextLayer:new(x, y, str, delegate, font)
  -- self.font = font or love.graphics.getFont()
  self.str = str or ''
  self.__font = font or love.graphics.getFont()
  self.__text = str or {}
  local width, height = parseLine(self, str)
  Layer.new(self, x, y, width, height, delegate)
end

function TextLayer:getFont()
  return rawget(self, '__font')
end

function TextLayer:getText()
  return rawget(self, '__text')
end

--- Setting draw font with font or font-name
--- @param font love.Font|string
--- @param size? integer
function TextLayer:setFont(font, size)
  if type(font) == 'string' then
    if size then
      font = FontManager[font][size]
    else
      font = FontManager[font].font
    end
  end

  rawset(self, '__font', font)

  -- Calculate real width height
  self:setSize(parseLine(self, rawget(self, 'str')))
end

--- @param str string
function TextLayer:setText(str)
  rawset(self, '__text', parseText(str))

  -- Calculate real width height
  self:setSize(parseLine(self, str))
end

function TextLayer:draw(x, y)
  local delegate = self.delegate
  x, y = (x or 0) + rawget(self, 1), (y or 0) + rawget(self, 2)
  -- print('draw', x, y)

  self:begin()

  if delegate then
    if type(delegate) == 'function' then
      delegate(self)

    else
      delegate:onDraw(self)
    end
  end

  ---@diagnostic disable-next-line: invisible, param-type-mismatch
  love.graphics.print(rawget(self, '__text'), rawget(self, '__font'), 0, 0)

  self:commit()

  love.graphics.draw(canvas, toQuad(self), x, y)

  for i = 9, #self do
    self[i]:draw(x, y)
  end
end

Object(Layer, TextLayer)

return TextLayer
