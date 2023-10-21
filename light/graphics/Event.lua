--- Light.lua
--- If I were the shore, bright & magnanimous.
--- @author Jakit Liang 泊凛
--- @date 2023-10-20
--- @license BSD 2-Clause License

local Object = require('light.Object')
local Vector2 = require('light.graphics.Vector2')

--- @class Event
--- @field handlers table<EventHandler, integer> Handler and zIndex
--- @field maxIndex integer Max zIndex
--- @field mousePos Vector2
--- @field [integer] EventHandler
--- @overload fun():Event
local Event = {
  mousePos = Vector2(0, 0),
  handlers = setmetatable({}, {__mode = 'k'}),
  maxIndex = 0
}

function Event:new() end

--- @class EventHandler
local EventHandler = {}

function EventHandler:checkPosition(x, y) end

function EventHandler:onMouseDown(x, y, button, istouch, presses) end

function EventHandler:onMouseUp(x, y, button, istouch, presses) end

function EventHandler:onMouseHover(x, y, dx, dy, istouch) end

function EventHandler:onMouseScroll(x, y) end

Object(EventHandler)

--- Bind an event handler
--- @param handler EventHandler
function Event:bind(handler)
  self.maxIndex = self.maxIndex + 1
  self.handlers[handler] = self.maxIndex
end

function Event:checkTop(x, y)
  local max, sel = 0, nil

  for k, v in pairs(self.handlers) do
    if k.checkPosition and k:checkPosition(x, y) then
      if v > max then
        max = v
        sel = k
      end
    end
  end

  return sel
end

function Event:mousepressed(x, y, button, istouch, presses)
  local sel = self:checkTop(x, y)

  if sel and sel.onMouseDown then
    sel:onMouseDown(x, y, button, istouch, presses)
  end
end

function Event:mousereleased(x, y, button, istouch, presses)
  local sel = self:checkTop(x, y)

  if sel and sel.onMouseUp then
    sel:onMouseUp(x, y, button, istouch, presses)
  end
end

function Event:wheelmoved(x, y)
  local posX, posY = love.mouse.getPosition()
  local sel = self:checkTop(posX, posY)

  if sel and sel.onMouseScroll then
    sel:onMouseScroll(x, y)
  end
end

function Event:mousemoved(x, y, dx, dy, istouch)
  local sel = self:checkTop(x, y)
  Vector2.setVector2(self.mousePos, x, y)

  if sel and sel.onMouseHover then
    sel:onMouseHover(x, y, dx, dy, istouch)
  end
end

function Event:MoveToTop(t)
  if not self.handlers[t] then
    return
  end

  self.maxIndex = self.maxIndex + 1
  self.handlers[t] = self.maxIndex
end

Object(Event)

return Event
