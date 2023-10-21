--- Light.lua
--- If I were the shore, bright & magnanimous.
--- @author Jakit Liang 泊凛
--- @date 2023-10-20
--- @license BSD 2-Clause License

local Object = require('light.Object')
local Layer = require('light.graphics.Layer')
local Vector2 = require('light.graphics.Vector2')

--- View is the basic game object
--- @class View : Object, LayerDelegate
--- @field layer Layer
--- @field position number, number
--- @field [integer] View
--- @field super View
--- @field freeze boolean
--- @field visible boolean
--- @field debug boolean
--- @overload fun(layer: Layer):self
local View = {}

--- @param layer Layer
function View:new(layer)
  self.layer = layer
  self.super = nil
  rawset(self, '__visible', false)
  self.freeze = false
  self.debug = false
end

--- Interface: Notifies the element when appears (Visible).
--- @protected
function View:onAppear() end

--- Interface: Notifies the element then disappears (Invisible).
--- @protected
function View:onDisappear() end

--- Interface: Update the data within element on each frame
--- @protected
function View:onUpdate(dt) end

--- Delegate from LayerDelegate
--- @param layer Layer
function View:onDraw(layer) end

function View:update(dt)
  if self.freeze or not self.visible then
    return
  end

  self.onUpdate(dt)

  for i = 1, #self do
    self[i]:update(dt)
  end
end

function View:draw(x, y)
  if not self.visible then
    return
  end

  x, y = (x or 0), (y or 0)
  local offsetX, offsetY = self:getPosition()

  self.layer:draw(x, y)

  for i = 1, #self do
    self[i]:draw(x + offsetX, y + offsetY)
  end
end

--- @return number x
function View:getX()
  return self.layer:getX()
end

--- @return number y
function View:getY()
  return self.layer:getX()
end

--- @return number width
function View:getWidth()
  return self.layer:getWidth()
end

--- @return number height
function View:getHeight()
  return self.layer:getHeight()
end

function View:getPosition()
  return self.layer:getPosition()
end

function View:getSize()
  return self.layer:getSize()
end

function View:getScreenPosition()
  local x, y = self:getPosition()
  local super = rawget(self, 'super')

  while super do
    x, y = super.layer:getX() + x, super.layer:getY() + y
    super = rawget(super, 'super')
  end

  return x, y
end

function View:getVisible()
  return rawget(self, '__visible')
end

--- @param visible boolean
function View:setVisible(visible)
  if rawget(self, '__visible') == visible then
    return
  end

  rawset(self, '__visible', visible)

  if visible then
    self:onAppear()

  else
    self:onDisappear()
  end
end

function View:setX(x)
  self.layer:setX(x)
end

function View:setY(y)
  self.layer:setY(y)
end

--- @param width number The width of size.
function View:setWidth(width)
  self.layer:setWidth(width)
end

--- @param height number The height of size.
function View:setHeight(height)
  self.layer:setHeight(height)
end

function View:setPosition(x, y)
  self.layer:setPosition(x, y)
end

function View:setSize(width, height)
  self.layer:setSize(width, height)
end

--- Append sub view to its hierarchy
--- @param view View
function View:add(view)
  view.super = self
  self[#self + 1] = view
  view:setVisible(true)
  view.freeze = false
end

--- Remove a sub view from its hierarchy
--- @param view View
function View:remove(view)
  for i = 1, #self do
    if self[i] == view then
      self[i].freeze = true
      self[i]:setVisible(false)
      table.remove(self, i)
      break
    end
  end
end

--- Remove self from its hierarchy
function View:removeFromSuper()
  self.super:remove(self)
end

function View:checkPosition(x, y)
  local sx, sy = self:getScreenPosition()

  if x < sx or y < sy then
    return false
  end

  if x > sx + self:getWidth() or y > sy + self:getHeight() then
    return false
  end

  return true
end

Object(View)

return View
