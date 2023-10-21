--- Light.lua
--- If I were the shore, bright & magnanimous.
--- @author Jakit Liang 泊凛
--- @date 2023-10-20
--- @license BSD 2-Clause License

local Object = require('light.Object')
local View = require('light.graphics.View')
local FontManager = require('light.graphics.FontManager')
local TextLayer = require('light.graphics.layer.TextLayer')

--- @class LabelView : View
--- @field font love.Font|string Font
--- @field layer TextLayer
--- @overload fun(x:number, y:number, str:string, font?:love.Font):self|any
local LabelView = {}

function LabelView:new(x, y, str, font)
  local textLayer = TextLayer(x, y, str, self, font)
  View.new(self, textLayer)
end

function LabelView:getFont()
  return self.layer:getFont()
end

function LabelView:setFont(font, size)
  self.layer:setFont(font, size)
end

function LabelView:setText(str)
  self.layer:setText(str)
end

Object(View, LabelView)

return LabelView
