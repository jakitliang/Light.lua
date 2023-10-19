--- Light.lua
--- Light up your way to the internet
--- @module 'WebSocketProtocol'
--- @author Jakit Liang 泊凛
--- @date 2023-09-16
--- @license MIT

-- Should help your self change the library
-- require('compat53')
-- require('love.data')

local Object = require('light.Object')
local Protocol = require('light.network.Protocol')
local ParseStatus = Protocol.ParseStatus
---@diagnostic disable-next-line: deprecated
local Pack = string.pack or function (...) return love.data.pack('string', ...) end
---@diagnostic disable-next-line: deprecated
local Unpack = string.unpack or function (...) return love.data.unpack(...) end
local bnot = bit.bnot
local band, bor, bxor = bit.band, bit.bor, bit.bxor
local lshift, rshift, rol = bit.lshift, bit.rshift, bit.rol
local Log = require('light.Log')

local ParseState = {
  PARSE_OPERATION = ParseStatus.BEGIN,
  PARSE_LEN = 1,
  PARSE_EXT_LEN = 2,
  PARSE_MASKING = 3,
  PARSE_PAYLOAD = 4
}

local Flags = {FLAG_FIN = lshift(1, 7), FLAG_MASK = lshift(1, 7)}

local OpCode = {
  OP_CONTINUE = 0x0,
  OP_TEXT = 0x1,
  OP_BIN = 0x2,
  OP_CLOSE = 0x8,
  OP_PING = 0x9,
  OP_PONG = 0xA
}

local PacketType = {
  SMALL = 0,
  MEDIUM = 1,
  LARGE = 2
}

--- @class WebSocketProtocol : Protocol
--- @field fin boolean
--- @field opCode integer
--- @field mask boolean
--- @field masking table
--- @field length integer
--- @field longEXT boolean
--- @field payload string
--- @overload fun():self
local WebSocketProtocol = {}

function WebSocketProtocol:new()
  Protocol.new(self)
  self.fin = true
  self.opCode = 0x0
  self.mask = false
  self.masking = {}
  self.length = 0
  self.packetType = PacketType.SMALL
  self.payload = ''
  self.state = ParseState.PARSE_OPERATION
end

--- @param source string
--- @param offset integer
--- @param size integer
local function CheckNeed(source, offset, size)
  if source:len() >= (offset - 1) + size then
    return true
  end

  return false
end

--- @param source string
--- @param offset integer
--- @param size integer
local function PacketSlice(source, offset, size)
  return source:sub(offset, (offset - 1) + size)
end

--- @param source string
function WebSocketProtocol:onUnpack(source)
  local state = self.state

  if state == ParseState.PARSE_OPERATION then
    return self:unpackOperation(source)

  elseif state == ParseState.PARSE_LEN then
    return self:unpackLen(source)

  elseif state == ParseState.PARSE_EXT_LEN then
    return self:unpackEXTLen(source)

  elseif state == ParseState.PARSE_MASKING then
    return self:unpackMasking(source)

  elseif state == ParseState.PARSE_PAYLOAD then
    return self:unpackPayload(source)
  end

  return self.status
end

--- @param source string
function WebSocketProtocol:unpackOperation(source)
  local offset = self.offset

  -- source:len() >= (offset - 1) + 1
  if CheckNeed(source, offset, 1) then
    -- local byte = source:sub(offset, (offset - 1) + 1)
    local byte = PacketSlice(source, offset, 1)
    local data = Unpack('B', byte)

    if band(data, Flags.FLAG_FIN) > 0 then
      self.fin = true
      data = data - Flags.FLAG_FIN

    else
      self.fin = false
    end

    self.opCode = data
    self.state = ParseState.PARSE_LEN
    self.offset = offset + 1

    return ParseStatus.CONTINUE
  end

  return ParseStatus.PENDING
end

--- @param source string
function WebSocketProtocol:unpackLen(source)
  local offset = self.offset

  if CheckNeed(source, offset, 1) then
    local byte = PacketSlice(source, offset, 1)
    local data = Unpack('B', byte)
    local len = data

    if band(data, Flags.FLAG_MASK) > 0 then
      self.mask = true
      len = data - Flags.FLAG_MASK
    end

    self.offset = offset + 1

    if len <= 125 then
      self.length = len

      if self.mask then
        self.state = ParseState.PARSE_MASKING

        return ParseStatus.CONTINUE
      end

      self.state = ParseState.PARSE_PAYLOAD
      return ParseStatus.CONTINUE

    elseif len == 126 then
      self.packetType = PacketType.MEDIUM

    else
      self.packetType = PacketType.LARGE
    end

    self.state = ParseState.PARSE_EXT_LEN

    return ParseStatus.CONTINUE
  end

  return ParseStatus.PENDING
end

--- @param source string
function WebSocketProtocol:unpackEXTLen(source)
  local offset = self.offset
  local extLenSize = 2
  local byteFormat = '>I2'

  if self.packetType == PacketType.LARGE then
    extLenSize = 8
    byteFormat = '>I8'
  end

  -- source:len() >= extLenSize + offset
  if CheckNeed(source, offset, extLenSize) then
    local bytes = PacketSlice(source, offset, extLenSize)
    self.length = Unpack(byteFormat, bytes)
    self.offset = offset + extLenSize

    if self.mask then
      self.state = ParseState.PARSE_MASKING

      return ParseStatus.CONTINUE
    end

    self.state = ParseState.PARSE_PAYLOAD
    return ParseStatus.CONTINUE
  end

  return ParseStatus.PENDING
end

--- @param source string
function WebSocketProtocol:unpackMasking(source)
  local offset = self.offset

  if CheckNeed(source, offset, 4) then
    local bytes = PacketSlice(source, offset, 4)
    self.masking = {bytes:byte(1, bytes:len())}
    self.offset = offset + 4
    self.state = ParseState.PARSE_PAYLOAD

    return ParseStatus.CONTINUE
  end

  return ParseStatus.PENDING
end

--- @param source string
function WebSocketProtocol:unpackPayload(source)
  local offset = self.offset

  if CheckNeed(source, offset, self.length) then
    local bytes = PacketSlice(source, offset, self.length)
    self.offset = offset + self.length

    if self.mask then
      local payLoadData = {bytes:byte(1, bytes:len())}

      local transformed = {}

      for i = 1, #payLoadData do
        local j = (i - 1) % 4 + 1
        transformed[i] = bit.bxor(payLoadData[i], self.masking[j])
      end

      self.payload = string.char(unpack(transformed))
      self.state = ParseState.PARSE_OPERATION

      return ParseStatus.COMPLETE
    end

    self.payload = bytes
    self.state = ParseState.PARSE_OPERATION

    return ParseStatus.COMPLETE
  end

  return ParseStatus.PENDING
end

function WebSocketProtocol:onPack()
  local data = self:packOperation()
  data = data .. self:packLen()

  if self.mask then
    data = data .. self:packMasking()
  end

  data = data .. self:packPayload()

  return data
end

function WebSocketProtocol:packOperation()
  local bytes = self.fin and 1 or 0
  return Pack('B', lshift(bytes, 7) + self.opCode)
end

function WebSocketProtocol:packLen()
  local bytes = self.mask and 1 or 0
  self.length = self.payload:len()

  if self.payload:len() < 126 then
    return Pack('B', lshift(bytes, 7) + self.length)

  elseif self.payload:len() <= 0xffff then
    return Pack('B>I2', lshift(bytes, 7) + 126, self.length)
  end

  return Pack('B>I8', lshift(bytes, 7) + 127, self.length)
end

function WebSocketProtocol:packMasking()
  math.randomseed(os.time())
  for i = 1, 4 do
    table.insert(self.masking, math.random(1, 200))
  end
  return string.char(unpack(self.masking))
end

function WebSocketProtocol:packPayload()
  if self.mask then
    local payLoadData = {self.payload:byte(1, self.payload:len())}

    local transformed = {}

    for i = 1, #payLoadData do
      local j = (i - 1) % 4 + 1
      transformed[i] = bit.bxor(payLoadData[i], self.masking[j])
    end

    self.payload = string.char(unpack(transformed))
  end

  return self.payload
end

Object(Protocol, WebSocketProtocol)

WebSocketProtocol.OpCode = OpCode

return WebSocketProtocol
