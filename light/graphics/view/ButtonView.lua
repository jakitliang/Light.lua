--- Light.lua
--- If I were the shore, bright & magnanimous.
--- @author Jakit Liang 泊凛
--- @date 2023-10-20
--- @license BSD 2-Clause License

local Object = require('light.Object')
local View = require('light.graphics.View')
local LabelView = require("light.graphics.view.LabelView")
local Layer = require('light.graphics.Layer')
local Event = require('light.graphics.Event')

--- @class ButtonView : View, EventHandler
--- @field textLabel LabelView
--- @field layer CanvasLayer
--- @overload fun(x:number,y:number,width:number,height:number,str?:string,font?):ButtonView|any
local ButtonView = {}

function ButtonView:new(x, y, width, height, str, font)
  View.new(self, Layer(x, y, width, height, self))
  self.textLabel = LabelView(0, 0, str, font)

  -- Put text center
  self.textLabel:setPosition(
    width / 2 - self.textLabel:getWidth() / 2,
    height / 2 - self.textLabel:getHeight() / 2
  )

  self:add(self.textLabel)
  Event:bind(self)
end

function ButtonView:onMouseUp(x, y, button, istouch, presses)
  print('hello world!')
  -- self:removeFromSuper()
end

function ButtonView:setFont(font)
  self.textLabel:setFont(font)

  -- Put text center
  self.textLabel:setPosition(
    self:getWidth() / 2 - self.textLabel:getWidth() / 2,
    self:getHeight() / 2 - self.textLabel:getHeight() / 2
  )
end

function ButtonView:onDraw()
  self.layer:setLineWidth(1.5)
  self.layer:rectangle("line", 0, 0, self:getWidth(), self:getHeight())
end

Object(View, ButtonView)

return ButtonView
