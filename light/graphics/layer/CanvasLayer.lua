--- Light.lua
--- If I were the shore, bright & magnanimous.
--- @author Jakit Liang 泊凛
--- @date 2023-10-20
--- @license BSD 2-Clause License

local Object = require('light.Object')
local Layer = require('light.graphics.Layer')
local Vector2 = require('light.graphics.Vector2')

--- CanvasLayer holds drawable canvas
--- @class CanvasLayer : Layer
--- @overload fun(x:number, y:number, width:number, height:number, delegate?:LayerDelegate|fun(layer: Layer)):self
local CanvasLayer = {}

local toQuad = rawget(Layer --[[@as Layer]], 'toQuad')

function CanvasLayer:new(x, y, width, height, delegate)
  Layer.new(self, x, y, width, height, delegate)
  Vector2.setVector2(self, width, height, 2)
  self.canvas = love.graphics.newCanvas(width, height)
end

function CanvasLayer:setFrameSize(width, height)
  Layer.setFrameSize(self, width, height)
  self.canvas = love.graphics.newCanvas(width, height)
end

--- Session: Commit to canvas
function CanvasLayer:setFrame(x, y, width, height)
  Layer.setFrame(self, x, y, width, height)
  self.canvas = love.graphics.newCanvas(width, height)
end

---------------------
--- Graphics Call ---
---------------------

--- Session: Begin drawing
function CanvasLayer:begin(clear)
  love.graphics.push("all") -- save all love.graphics state so any changes can be restored
  -- love.graphics.translate(self:getPosition())
  love.graphics.setCanvas(self.canvas)
  if clear then
    love.graphics.clear()
  end
end

function CanvasLayer:draw(x, y)
  local delegate = self.delegate
  x, y = (x or 0) + rawget(self, 1), (y or 0) + rawget(self, 2)

  self:begin(true)

  if delegate then
    if type(delegate) == 'function' then
      delegate(self)

    else
      delegate:onDraw(self)
    end
  end

  self:commit()

  self:begin()
  for i = 9, #self do
    self[i]:draw(0, 0)
  end
  self:commit()

  love.graphics.draw(self.canvas, toQuad(self), x, y)
end

Object(Layer, CanvasLayer)

return CanvasLayer
