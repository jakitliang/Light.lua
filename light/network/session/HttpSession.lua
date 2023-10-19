--- Light.lua
--- Light up your way to the internet
--- @module 'HttpSession'
--- @author Jakit Liang 泊凛
--- @date 2023-09-16
--- @license MIT

local Object = require('light.object')
local Socket = require('socket')
local TCPSession = require('light.network.session.tcp_session')
local HttpProtocol = require('light.network.protocol.http_protocol')
local HttpMethod = HttpProtocol.HttpMethod
local HttpStatus = HttpProtocol.HttpStatus
local HttpMIME = HttpProtocol.HttpMIME
local WebSocketProtocol = require('light.network.protocol.websocket_protocol')
local Log = require('light.log')

--- @class HttpSession : TCPSession
--- @field delegate HttpSessionDelegate|fun(...):nil|Protocol
--- @field input any
--- @field output any
--- @field request HttpProtocol|WebSocketProtocol
--- @field response HttpProtocol|WebSocketProtocol
--- @overload fun(host: string, port: integer, delegate, channel):self
local HttpSession = {}

--- @class HttpSessionDelegate : Object
local HttpSessionDelegate = Object()

--- @param session HttpSession
--- @param input HttpProtocol
--- @param output HttpProtocol
--- @return nil|HttpProtocol|WebSocketProtocol
function HttpSessionDelegate:onHttp(session, input, output) end

--- @param session HttpSession
--- @param input WebSocketProtocol
--- @param output WebSocketProtocol
--- @return nil|HttpProtocol|WebSocketProtocol
function HttpSessionDelegate:onWebSocket(session, input, output) end

--- @param session HttpSession
function HttpSessionDelegate:onSendCompletion(session) end

--- @param self HttpSession
local function HttpSessionInitProtocol(self, host, port)
  if self.isWebsocket then
    self.request = WebSocketProtocol()
    self.response = WebSocketProtocol()
    return
  end

  self.request = HttpProtocol(host .. (port or ''))
  self.response = HttpProtocol()
end

function HttpSession:new(host, port, delegate, channel)
  TCPSession.new(self, host, port, channel)

  self.isWebsocket = false
  self.isServer = channel and true or false
  self.delegate = delegate
  HttpSessionInitProtocol(self, host, port)
end

--- @param input HttpProtocol
--- @param output HttpProtocol
local function HttpUpgradeServer(input, output)
  local websocketKey = input.headers["sec-websocket-key"]
  local securityKey = '258EAFA5-E914-47DA-95CA-C5AB0DC85B11'
  local digestKey = Socket.base64encode(Socket.sha1(websocketKey .. securityKey))

  output.statusCode = 101
  output.headers["connection"] = "keep-alive, Upgrade"
  output.upgrade = "websocket"
  output.headers["sec-websocket-accept"] = digestKey
end

--- @param channel TCPChannel
--- @param input WebSocketProtocol
--- @param output WebSocketProtocol
--- @return nil|Protocol
function HttpSession:onReadWebSocket(channel, input, output)
  -- Log:debug('HttpSession:onReadWebSocket', input.payload)
  local opCode = input.opCode
  local delegate = self.delegate

  if opCode == WebSocketProtocol.OpCode.OP_CLOSE then
    channel:close()
    return

  elseif opCode == WebSocketProtocol.OpCode.OP_PING then
    output.opCode = WebSocketProtocol.OpCode.OP_PONG
    output.payload = input.payload
    return output

  elseif opCode == WebSocketProtocol.OpCode.OP_PONG then
    output.opCode = WebSocketProtocol.OpCode.OP_PING
    output.payload = input.payload
    return output
  end

  output.opCode = opCode
  -- output.payload = 'hello! ' .. input.payload

  if delegate then
    if type(delegate) == 'function' then
      return delegate('onWebSocket', self, input, output)
    end

    return delegate:onWebSocket(self, input, output)
  end
end

--- @param channel TCPChannel
--- @param input HttpProtocol
--- @param output HttpProtocol
--- @return nil|Protocol
function HttpSession:onReadHttp(channel, input, output)
  local delegate = self.delegate

  if input.upgrade then
    self.isWebsocket = true

    if self.isServer then
      HttpUpgradeServer(input, output)
      return output
    end

    return nil
  end

  -- output.headers['content-type'] = HttpMIME.HTML
  -- output.content = '<html><h1>It Works!</h1><p>Power by <b>Light v0.1<b></p></html>'

  if delegate then
    if type(delegate) == 'function' then
      return delegate('onHttp', self, input, output)
    end

    return delegate:onHttp(self, input, output)
  end
end

--- @param channel TCPChannel
--- @param buffer string
--- @return integer
function HttpSession:onRead(channel, buffer)
  -- Log:debug('HttpSession:onRead', tostring(channel))
  local input = self.input
  local ret = nil

  local status, offset = input:unpack(buffer)

  if status == input.ParseStatus.ERROR then
    channel:close()
    return offset

  elseif status == input.ParseStatus.CONTINUE then
    return offset

  elseif status == input.ParseStatus.PENDING then
    return offset
  end

  if self.isWebsocket then
    ret = self:onReadWebSocket(channel, input, self.output)

  else
    ret = self:onReadHttp(channel, input, self.output)
  end

  if ret then
    self:send(ret)
  end

  HttpSessionInitProtocol(self, self.host, self.port) -- Reset
  return offset
end

function HttpSession:completion(count)
  -- Log:debug('HttpSession:completion', count)
  local delegate = self.delegate

  if delegate then
    if type(delegate) == 'function' then
      for i = 1, count do
        delegate('onSendCompletion', self)
      end
      return
    end

    for i = 1, count do
      delegate:onSendCompletion(self)
    end
  end
end

--- @param protocol Protocol
function HttpSession:send(protocol)
  local buffer = protocol:pack()
  TCPSession.send(self, buffer, #buffer)
end

function HttpSession:sendHandShake()
  local request = HttpProtocol(self.host .. (self.port or ''))

  request.method = 'GET'
  request.headers["connection"] = "Upgrade"
  request.upgrade = "websocket"
  request.headers["Sec-WebSocket-Key"] = 'dGhlIHNhbXBsZSBub25jZQ=='
  request.headers["Sec-WebSocket-Version"] = '13'

  self:send(request)
end

function HttpSession:getInput()
  return self.isServer and self.request or self.response
end

function HttpSession:getOutput()
  return self.isServer and self.response or self.request
end

Object(TCPSession, HttpSession)

HttpSession.Delegate = HttpSessionDelegate

return HttpSession
