--- Light.lua
--- If I were the shore, bright & magnanimous.
--- @author Jakit Liang 泊凛
--- @date 2023-10-20
--- @license BSD 2-Clause License

local Object = require('light.Object')
local Vector2 = require('light.graphics.Vector2')
local Vector4 = require('light.graphics.Vector4')
local FontManager = require('light.graphics.FontManager')

--- Layer is Drawable things
--- @class Layer : Object
--- @field x number The visible width
--- @field y number The visible height
--- @field width number The visible width
--- @field height number The visible height
--- @field delegate LayerDelegate|fun(layer: Layer)
--- @overload fun(x:number, y:number, width:number, height:number, delegate?:LayerDelegate|fun(layer: Layer)):Layer
local Layer = {}

--- @class LayerDelegate : Object
local LayerDelegate = {}

--- @param layer Layer
function LayerDelegate:onDraw(layer) end

Object(LayerDelegate)

local quad = love.graphics.newQuad(
  0, 0, 0, 0, 0, 0
)

local canvas = love.graphics.newCanvas()
local canvasWidth, canvasHeight = canvas:getDimensions()

--- @param self Layer
local function toQuad(self)
  local x, y, width, height = self:getBound()
  quad:setViewport(x, y, width, height, Vector2.getVector2(self, 2))
  return quad
end

local function colorFromHEX(rgba)
  local rb = tonumber(string.sub(rgba, 2, 3), 16)
  local gb = tonumber(string.sub(rgba, 4, 5), 16)
  local bb = tonumber(string.sub(rgba, 6, 7), 16)
  local ab = tonumber(string.sub(rgba, 8, 9), 16) or nil
  --  print (rb, gb, bb, ab) -- prints  51  102 153 204
  --  print (love.math.colorFromBytes( rb, gb, bb, ab )) -- prints  0.2 0.4 0.6 0.8
  love.graphics.setColor (love.math.colorFromBytes(rb, gb, bb, ab))
  return rb / 255, gb / 255, bb / 255, ab and ab / 255
end

function Layer:new(x, y, width, height, delegate)
  Vector4.setVector4(self, x, y, canvasWidth, canvasHeight)
  Vector4.setVector4(self, 0, 0, width, height, 4)
  self.delegate = delegate
end

--- @return number x
function Layer:getX()
  return rawget(self, 1)
end

--- @return number y
function Layer:getY()
  return rawget(self, 2)
end

--- @return number width
function Layer:getWidth()
  return rawget(self, 7)
end

--- @return number height
function Layer:getHeight()
  return rawget(self, 8)
end

--- @return number x, number y
function Layer:getPosition()
  return Vector2.getVector2(self)
end

--- @return number width, number height
function Layer:getSize()
  return Vector2.getVector2(self, 6)
end

function Layer:getFrame()
  return Vector4.getVector4(self)
end

--- @return number x, number y, number width, number height
function Layer:getBound()
  return Vector4.getVector4(self, 4)
end

--- @param x number The top-left corner along the x-axis.
function Layer:setX(x)
  rawset(self, 1, x)
end

--- @param y number The top-left corner along the y-axis.
function Layer:setY(y)
  rawset(self, 2, y)
end

--- @param width number The width of size.
function Layer:setWidth(width)
  rawset(self, 7, width)
end

--- @param height number The height of size.
function Layer:setHeight(height)
  rawset(self, 8, height)
end

--- Set view position
--- @param x number The top-left corner along the x-axis.
--- @param y number The top-left corner along the y-axis.
function Layer:setPosition(x, y)
  Vector2.setVector2(self, x, y)
end

--- Set view size
--- @param width number The width of size.
--- @param height number The height of size.
function Layer:setSize(width, height)
  Vector2.setVector2(self, width, height, 6)
end

function Layer:setFrameSize(width, height)
  Vector2.setVector2(self, width, height, 2)
end

function Layer:setFrame(x, y, width, height)
  Vector4.setVector4(self, x, y, width, height)
end

function Layer:setBoundPosition(x, y)
  Vector2.setVector2(self, x, y, 4)
end

--- Set viewport
--- @param x number The top-left corner along the x-axis.
--- @param y number The top-left corner along the y-axis.
--- @param width number The width of the viewport.
--- @param height number The height of the viewport.
function Layer:setBound(x, y, width, height)
  Vector4.setVector4(self, x, y, width, height, 4)
end

function Layer:add(layer)
  self[#self + 1] = layer
end

function Layer:remove(layer)
  for i = 9, #self do
    if layer == self[i] then
      table.remove(self, i)
      break
    end
  end
end

---------------------
--- Graphics Call ---
---------------------

--- Session: Begin drawing
function Layer:begin()
  love.graphics.push("all") -- save all love.graphics state so any changes can be restored
  -- love.graphics.translate(self:getPosition())
  love.graphics.setCanvas(canvas)
  love.graphics.clear()
end

--- Session: Commit to canvas
function Layer:commit()
  love.graphics.pop() -- restore the saved love.graphics state
end

function Layer:draw(x, y)
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

  self:commit()
  love.graphics.draw(canvas, toQuad(self), x, y)

  for i = 9, #self do
    self[i]:draw(x, y)
  end
end

---@overload fun(self, texture: love.Texture, quad: love.Quad, x: number, y: number, r?: number, sx?: number, sy?: number, ox?: number, oy?: number, kx?: number, ky?: number)
---@overload fun(self, drawable: love.Drawable, transform: love.Transform)
---@overload fun(self, texture: love.Texture, quad: love.Quad, transform: love.Transform)
---@param drawable love.Drawable # A drawable object.
---@param x? number # The position to draw the object (x-axis).
---@param y? number # The position to draw the object (y-axis).
---@param r? number # Orientation (radians).
---@param sx? number # Scale factor (x-axis).
---@param sy? number # Scale factor (y-axis).
---@param ox? number # Origin offset (x-axis).
---@param oy? number # Origin offset (y-axis).
---@param kx? number # Shearing factor (x-axis).
---@param ky? number # Shearing factor (y-axis).
function Layer:paint(drawable, x, y, r, sx, sy, ox, oy, kx, ky)
  love.graphics.draw(drawable, x, y, r, sx, sy, ox, oy, kx, ky)
end

--- @param width number
function Layer:setLineWidth(width)
  love.graphics.setLineWidth(width)
end

--- Layer set color
--- @overload fun(self, r: string)
--- @param r number
--- @param g number
--- @param b number
--- @param a number
function Layer:setColor(r, g, b, a)
  if type(r) == 'string' then
    local _a
    r, g, b, _a = colorFromHEX(r)
    a = _a or a or 1
  end

  love.graphics.setColor(r, g, b, a)
end

local function getFont(name, size)
  if size then
    return FontManager[name][size]
  end

  return FontManager[name].font
end

--- Setting draw font with font or font-name
--- @param font love.Font|string
function Layer:setFont(font, size)
  if type(font) == 'string' then
    font = getFont(font, size)
  end

  love.graphics.setFont(font)
end

--- Layer drawing rectangle
--- @param mode love.DrawMode
--- @param x number
--- @param y number
--- @param width number
--- @param height number
function Layer:rectangle(mode, x, y, width, height)
  love.graphics.rectangle(mode, x, y, width, height)
end

--- Print plain string
--- @param str string
--- @param x? number Position X
--- @param y? number Position Y
--- @param r? number Radians
--- @param sx? number Scale X
--- @param sy? number Scale Y
--- @param ox? number Offset X
--- @param oy? number Offset Y
--- @param kx? number Shearing / skew factor on the x-axis
--- @param ky? number Shearing / skew factor on the y-axis
function Layer:print(str, x, y, r, sx, sy, ox, oy, kx, ky)
  love.graphics.print(str, x, y, r, sx, sy, ox, oy, kx, ky)
end

--- Print plain string
--- @param str string
--- @param font love.Font|string Font or font name
--- @param x? number Position X
--- @param y? number Position Y
--- @param r? number Radians
--- @param sx? number Scale X
--- @param sy? number Scale Y
--- @param ox? number Offset X
--- @param oy? number Offset Y
--- @param kx? number Shearing / skew factor on the x-axis
--- @param ky? number Shearing / skew factor on the y-axis
function Layer:printWithFont(str, font, x, y, r, sx, sy, ox, oy, kx, ky)
  if type(font) == 'string' then
    font = getFont(font)
  end
  ---@diagnostic disable-next-line: redundant-parameter
  love.graphics.print(str, font, x, y, r, sx, sy, ox, oy, kx, ky)
end

--- Print formatted text
--- @param text table Formatted text table {{r,g,b,a}, str, ...}
--- @param x? number Position X
--- @param y? number Position Y
--- @param r? number Radians
--- @param sx? number Scale X
--- @param sy? number Scale Y
--- @param ox? number Offset X
--- @param oy? number Offset Y
--- @param kx? number Shearing / skew factor on the x-axis
--- @param ky? number Shearing / skew factor on the y-axis
function Layer:printText(text, x, y, r, sx, sy, ox, oy, kx, ky)
  love.graphics.print(text, x, y, r, sx, sy, ox, oy, kx, ky)
end

--- Print formatted text
--- @param text table Formatted text table {{r,g,b,a}, str, ...}
--- @param font love.Font|string Font or font name
--- @param x? number Position X
--- @param y? number Position Y
--- @param r? number Radians
--- @param sx? number Scale X
--- @param sy? number Scale Y
--- @param ox? number Offset X
--- @param oy? number Offset Y
--- @param kx? number Shearing / skew factor on the x-axis
--- @param ky? number Shearing / skew factor on the y-axis
function Layer:printTextWithFont(text, font, x, y, r, sx, sy, ox, oy, kx, ky)
  if type(font) == 'string' then
    font = getFont(font)
  end
  ---@diagnostic disable-next-line: redundant-parameter
  love.graphics.print(text, font, x, y, r, sx, sy, ox, oy, kx, ky)
end

---@diagnostic disable-next-line: param-type-mismatch
rawset(Layer, 'FallBackCanvas', canvas)
---@diagnostic disable-next-line: param-type-mismatch
rawset(Layer, 'toQuad', toQuad)

Object(Layer)

return Layer
