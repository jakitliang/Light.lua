
io.stdout:setvbuf('no')

local Layer = require('light.graphics.Layer')
local CanvasLayer = require('light.graphics.layer.CanvasLayer')
local ImageLayer = require('light.graphics.layer.ImageLayer')
local TextLayer = require('light.graphics.layer.TextLayer')

local l1, l2
local lt = TextLayer(10, 10, "Hello World!")
local lm = ImageLayer(100, 100, "test/test.png")

local function load(args)
  l1 = Layer(10, 10, 25, 25,
    function (layer)
      layer:setColor("#ff0000")
      love.graphics.rectangle('fill', layer:getBound())
    end
  )
  l2 = CanvasLayer(50, 50, 50, 50,
    function (layer)
      layer:setColor("#0000ff")
      love.graphics.rectangle('fill', layer:getBound())
    end
  )
  l3 = CanvasLayer(10, 10, 25, 25,
    function (layer)
      layer:setColor("#ffff00")
      love.graphics.rectangle('fill', layer:getBound())
    end
  )
  l1:add(l3)
  l2:add(l1)
end

local function update(dt)

end

local function draw()
  l1:draw()
  l2:draw()
  lt:draw()
  lm:draw()
end

return function (love)
  love.load = load
  love.update = update
  love.draw = draw
end
