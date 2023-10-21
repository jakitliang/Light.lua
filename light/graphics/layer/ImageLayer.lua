--- Light.lua
--- If I were the shore, bright & magnanimous.
--- @author Jakit Liang 泊凛
--- @date 2023-10-20
--- @license BSD 2-Clause License

local Object = require('light.Object')
local Layer = require('light.graphics.Layer')
local Vector2 = require('light.graphics.Vector2')

--- @class ImageLayer : Layer
--- @field image love.Image
--- @overload fun(x:number, y:number, path:string):self
local ImageLayer = {}

local toQuad = rawget(Layer --[[@as Layer]], 'toQuad')

function ImageLayer:new(x, y, path)
  local image = love.graphics.newImage(path)
  local width, height = image:getDimensions()

  Layer.new(self, x, y, width, height)
  Vector2.setVector2(self, width, height, 2)

  self.image = image
end

function ImageLayer:draw(x, y)
  local delegate = self.delegate
  x, y = (x or 0) + rawget(self, 1), (y or 0) + rawget(self, 2)
  -- print('draw', x, y)

  love.graphics.draw(self.image, toQuad(self), x, y)

  for i = 9, #self do
    self[i]:draw(x, y)
  end
end

Object(Layer, ImageLayer)

return ImageLayer
