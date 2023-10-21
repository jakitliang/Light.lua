
io.stdout:setvbuf('no')

local View = require('light.graphics.View')
local LabelView = require('light.graphics.view.LabelView')
local ButtonView = require('light.graphics.view.ButtonView')
local Event = require('light.graphics.Event')
local helloLabel
local testButton

local function load(args)
  helloLabel = LabelView(0, 0, 'Hello')
  -- helloLabel.visible = true

  testButton = ButtonView(50, 0, 60, 30, 'Test')
  testButton.visible = true
end

local function update(dt)
  -- body
end

local function mousereleased(x, y, button, istouch, presses)
  Event:mousereleased(x, y, button, istouch, presses)
end

local function draw()
  helloLabel:draw()
  testButton:draw()
end

return function (love)
  love.load = load
  love.update = update
  love.draw = draw
  love.mousereleased = mousereleased
end
