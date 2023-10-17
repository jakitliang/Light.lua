--- Light.lua
--- Light up your way to the internet
--- @module 'HttpProtocol'
--- @author Jakit Liang 泊凛
--- @date 2023-09-16
--- @license MIT

local Object = require('core.object')
local Protocol = require('core.network.protocol')
local ParseStatus = Protocol.ParseStatus
local Log = require('core.log')

--- @class HttpProtocol : Protocol
--- @field headers table<string, string>
--- @field content string
--- @field method string
--- @field path string
--- @field version string
--- @field statusCode integer
--- @field statusMessage string
--- @field upgrade string
--- @overload fun(host?: string):self
local HttpProtocol = {}

local ParseState = {
  PARSE_HEAD = 0,
  PARSE_HEADERS = 1,
  PARSE_CONTENT = 2
}

local HttpMethod = {
  HEAD = 'HEAD',
  GET = 'GET',
  POST = 'POST',
  PUT = 'PUT',
  DELETE = 'DELETE'
}

local HttpMIME = {
  TEXT = "text/plain",
  HTML = "text/html",
  JSON = "application/json"
}

--- @enum HttpStatus
local HttpStatus = {}
HttpStatus[100] = 'Continue'
HttpStatus[101] = 'Switching Protocols'
HttpStatus[200] = 'OK'
HttpStatus[201] = 'Created'
HttpStatus[202] = 'Accepted'
HttpStatus[203] = 'Non-Authoritative Information'
HttpStatus[204] = 'No Content'
HttpStatus[205] = 'Reset Content'
HttpStatus[206] = 'Partial Content'
HttpStatus[300] = 'Multiple Choices'
HttpStatus[301] = 'Moved Permanently'
HttpStatus[302] = 'Found'
HttpStatus[303] = 'See Other'
HttpStatus[304] = 'Not Modified'
HttpStatus[305] = 'Use Proxy'
HttpStatus[306] = 'Unused'
HttpStatus[307] = 'Temporary Redirect'
HttpStatus[400] = 'Bad Request'
HttpStatus[401] = 'Unauthorized'
HttpStatus[402] = 'Payment Required'
HttpStatus[403] = 'Forbidden'
HttpStatus[404] = 'Not Found'
HttpStatus[405] = 'Method Not Allowed'
HttpStatus[406] = 'Not Acceptable'
HttpStatus[407] = 'Proxy Authentication Required'
HttpStatus[408] = 'Request Time-out'
HttpStatus[409] = 'Conflict'
HttpStatus[410] = 'Gone'
HttpStatus[411] = 'Length Required'
HttpStatus[412] = 'Precondition Failed'
HttpStatus[413] = 'Request Entity Too Large'
HttpStatus[414] = 'Request-URI Too Large'
HttpStatus[415] = 'Unsupported Media Type'
HttpStatus[416] = 'Requested range not satisfiable'
HttpStatus[417] = 'Expectation Failed'
HttpStatus[500] = 'Internal Server Error'
HttpStatus[501] = 'Not Implemented'
HttpStatus[502] = 'Bad Gateway'
HttpStatus[503] = 'Service Unavailable'
HttpStatus[504] = 'Gateway Time-out'
HttpStatus[505] = 'HTTP Version not supported'

local EOL = '\r\n'

--- @param str string
--- @param first integer
--- @param last integer
--- @param delimiter string
local function PopSplit(str, first, last, delimiter)
  local tmp = str:find(delimiter, first + 1)
  if not tmp then return nil, first, last end
  first = tmp
  return str:sub(last, first - 1), first, first + delimiter:len()
end

local function split(str, delimiter)
  local ret = {}
  for k, v in string.gmatch(str, "([^" .. delimiter .. "]+)") do
    ret[#ret + 1] = k
  end
  return ret
end

--- @param source string
--- @param offset integer
--- @param size number
local function CheckNeed(source, offset, size)
  if source:len() >= (offset - 1) + size then
    return true
  end

  return false
end

--- @param source string
--- @param offset integer
--- @param size number
local function PacketSlice(source, offset, size)
  return source:sub(offset, (offset - 1) + size)
end

--- @param host string
function HttpProtocol:new(host)
  Protocol.new(self)
  if host then
    self[1] = HttpMethod.HEAD
    self[2] = '/'
    self[3] = 'HTTP/1.1'
    self.headers = {
      ['host'] = host,
      ['user-agent'] = 'Light v0.1',
      ['connection'] = 'keep-alive',
    }

  else
    self[1] = 'HTTP/1.1'
    self[2] = 200
    self[3] = HttpStatus[200]
    self.headers = {
      server = 'Light v0.1',
      connection = 'keep-alive'
    }
  end

  self.content = ''
  self.state = ParseState.PARSE_HEAD
end

--- @param source string
function HttpProtocol:onUnpack(source)
  local state = self.state

  if state == ParseState.PARSE_HEAD then
    return self:unpackHead(source)

  elseif state == ParseState.PARSE_HEADERS then
    return self:unpackHeaders(source)

  elseif state == ParseState.PARSE_CONTENT then
    return self:unpackContent(source)
  end

  return self.status
end

function HttpProtocol:unpackHead(source)
  local offset = self.offset
  local first, last = offset, offset

  local line, first, last = PopSplit(source, first, last, EOL)

  if not line then
    return ParseStatus.PENDING
  end

  self.offset = last

  local a, b, c = unpack(split(line, ' '))

  if a and b and c then
    self[1], self[2], self[3] = a, tonumber(b) or b, c

  else
    return ParseStatus.ERROR
  end

  self.state = ParseState.PARSE_HEADERS
  return ParseStatus.CONTINUE
end

function HttpProtocol:unpackHeader(headerLines)
  for i = 1, #headerLines do
    local t = split(headerLines[i], ': ')
    if #t > 1 then
      self.headers[string.lower(t[1])] = t[2]
    end
  end
end

function HttpProtocol:unpackHeaders(source)
  local offset = self.offset
  local first, last = offset, offset
  local headerLines = {}
  local ok = false
  local line = nil

  line, first, last = PopSplit(source, first, last, EOL)
  while line do
    table.insert(headerLines, line)
    if line == '' then -- Meet empty line
      ok = true
      break
    end
    line, first, last = PopSplit(source, first, last, EOL)
  end

  if not ok then
    return ParseStatus.PENDING
  end

  self.offset = last

  self:unpackHeader(headerLines)

  if self.headers['content-length'] then
    self.state = ParseState.PARSE_CONTENT
    return ParseStatus.CONTINUE
  end

  self.state = ParseState.PARSE_HEAD
  return ParseStatus.COMPLETE
end

function HttpProtocol:unpackContent(source)
  local offset = self.offset
  local size = tonumber(self.headers['content-length']) or 0

  if CheckNeed(source, offset, size) then
    self.content = PacketSlice(source, offset, size)
    self.offset = self.offset + size

    self.state = ParseState.PARSE_HEAD
    return ParseStatus.COMPLETE
  end

  return ParseStatus.PENDING
end

function HttpProtocol:onPack()
  local line = {table.concat({self[1], self[2], self[3]}, ' ')}
  self.headers['content-length'] = self.content and tostring(#self.content) or 0

  for k, v in pairs(self.headers) do
    table.insert(line, k .. ': ' .. v)
  end

  return table.concat(line, "\r\n") .. EOL .. EOL .. (self.content or '')
end

function HttpProtocol:isRequest()
  return not self:isResponse()
end

function HttpProtocol:isResponse()
  return type(self[2]) == 'number'
end

--- @return string
function HttpProtocol:getMethod()
  return self[1]
end

--- @return string
function HttpProtocol:getPath()
  return self[2]
end

--- @return string
function HttpProtocol:getVersion()
  return self:isRequest() and self[3] or self[1]
end

--- @return string
function HttpProtocol:getStatusCode()
  return self[2]
end

--- @return string
function HttpProtocol:getStatusMessage()
  return self[3]
end

function HttpProtocol:getUpgrade()
  return self.headers['upgrade']
end

function HttpProtocol:setMethod(method)
  self[1] = HttpMethod[method] or self[1]
end

function HttpProtocol:setPath(path)
  self[2] = path
end

function HttpProtocol:setStatusCode(code)
  if type(code) == 'number' then
    self[2] = code
    self[3] = HttpStatus[code]
  end
end

--- @param protocol string
function HttpProtocol:setUpgrade(protocol)
  self.headers['upgrade'] = protocol
end

Object(Protocol, HttpProtocol)
HttpProtocol.HttpMethod = HttpMethod
HttpProtocol.HttpStatus = HttpStatus
HttpProtocol.HttpMIME = HttpMIME

return HttpProtocol
