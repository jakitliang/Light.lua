# Light.lua

> If I were the shore, bright &amp; magnanimous.

The goal of `Light` is to become the **FULL STACK** library in `Lua`.

You make everything with it, such like Mobile Apps, PC games, and Web backend, etc.

## Introduction

`Light` currently has 6 modules:

- **Object** provides prototype-oriented programming basic classes
- **Record** Provides ORM basic capabilities
- **Worker** Provides coroutines and event machines
- **Log** Provides basic log output
- **Socket** Provides cross-platform socket functionality and a small number of encryption and decryption methods.
- **Network** Provides Http and WebSocket network communication capabilities, and TCP basic capabilities.
- **Graphics** Privides Love2d compatible UI components.

## Installation

> luarocks install Light

### Dependency

#### SQLite3

> luarocks install lsqlite3

`light.record` is base on `lsqlite3` but it is not automatically installed.

So You need to install SQLite3:

- `apt get install libsqlite3-dev` in `ubuntu` linux.
- On windows, you should build SQLite3 with source code or download one prebuilt binary.

## Object

> light.Object -> Object

Designed with a Linked List like structure that is most suitable for the Lua language.

It provides high-performance method calling and similar features to JavaScript.

Sample:

```lua
local Object = require('light.Object')

local Base = Object()

-- Tips:
-- You can also do like this
--
-- local Base = {}
-- Object(Base)
--
-- or
--
-- local Base = Object({})

local b = Base()

print(b:instanceOf(Base))
print(b.proto == Base)

-- Make Derived inherit from Base
local Derived = Object(Base)

-- Tips:
-- You can also do like this
--
-- local Derived = {}
-- Object(Base, Derived)

local d = Derived()

print(d:instanceOf(Derived)) -- Will print "true"
print(d.proto == Derived)    -- Will print "true"
print(d:instanceOf(Base))    -- Will print "true"
print(d.proto == Base)       -- Will print "true"
```

## Record

> light.Record -> Record

Record is the ORM module of the database, who's the role of Model in MVC / MVVM.

Record take you the features equivalent to `SQLAlchemy` or `ActiveRecord` in `Lua`.

In brief, `Record` does the **CRUD** things of database.

Sample:

```lua
local u = Users()
u.name = 'demo'..i
u.age = i
print('User.save', u, u:save(), u.id)

u:save() -- Save

u:update() -- Change, Modify

u:destroy() -- Delete

Users:find({ -- Search
  id = 1
})
```

### Device

> light.Device -> Device

The device provides a scalable interface to facilitate users to access other data storage.

User can implemented their own DBC interface as a driver.

## Worker

> light.Worker -> Worker

An interface class implemented based on `Lua` coroutine `rotoutine` and combined with `light.Object`

### Event Worker

> light.worker.EventWorker -> EventWorker

The Event Worker (also Event Machine) was implemented using the cross-platform socket `light.socket`.

Equivalent to `libevent` and `libuv`, provides asynchronous event handling for IO.

## Log

> light.Log -> Log

Sample:

```lua
Log.level = Log.Level.DEBUG

Log:info('Hi,', 'here is themessage')
Log:warningF('warning %d', 123)
Log:error('error')
Log:debug('debug')
```

## Socket

Provides cross-platform socket support:

- Windows
- Linux
- macOS
- iOS

### TCP

> light.socket.TCP -> TCP

Sample:

```lua
local s = light.socket.TCP()
s:connect('localhost', 8080)
```

### UDP

> light.socket.UDP -> UDP

**UDP said it will coming soon**

### Base64

#### encode

> light.socket.base64encode -> fun(string)

#### decode

> light.socket.base64decode -> fun(string)

### SHA1

> light.socket.sha1 -> fun(string)

### SHA1Hex

> light.socket.sha1hex -> fun(string)

## Network

### Channel

#### TCPChannel

> light.network.channel.TCPChannel -> TCPChannel

TCP channel is the most basic TCP message sending pipe.

Users can operate in the following ways:

- TCPChannel:connect('host', port)
- TCPChannel:connectNow('host', port) -- NonBlock
- TCPChannel:read(1024)
- TCPChannel:readNow(1024) - NonBlock
- TCPChannel:write('buffer', 6)
- TCPChannel:writeNow('buffer', 6) - NonBlock
- TCPChannel:close()

#### TCPServerChannel

> light.network.channel.TCPServerChannel -> TCPServerChannel

TCP channel is a pipe for TCP service application.

Users can operate in the following ways:

- TCPChannel:accept()
- TCPChannel:acceptNow() -- NonBlock
- TCPChannel:close()

### Protocol

> light.Protocol -> Protocol

Protocol is the interface for data **serialization** and **deserialization**.

It is state machine-based designed so users should obey to the encode and decode state.

#### HttpProtocol

> light.network.protocol.HttpProtocol -> HttpProtocol

Implemented the standard HTTP 1.1 protocol encode and decode.

Providing status information attributes:

- statusCode
- statusMessage
- method
- path
- headers
- content

And also MIME：

> HttpProtocol.MIME

#### WebSocketProtocol

> light.network.protocol.WebsocketProtocol -> WebsocketProtocol

A WebSocketProtocol codec.

Provide status information attributes:

- fin
- mask
- masking
- length
- payload -- Message entity is here
- ...

### Session

The session was implement with **event machine** so IO is asynchronized.

Would provides `delegate` interface and function interface.

Using function interface is more easy.

#### TCPSession

> light.network.session.TCPSession -> TCPSession

#### TCPServerSession

> light.network.session.TCPServerSession -> TCPServerSession

#### HttpSession

> light.network.session.HttpSession -> HttpSession

This client classes a fusion of HttpSession and WebSocketSession

You can handle those message in one.

Users can use it directly and quickly build **event-based** client applications by setting the `delegate` or a callback funtion.

Sample:

```lua
local HttpSession = require('light.network.session.HttpSession')
local WebSocketProtocol = require('light.network.protocol.WebSocketProtocol')

local s = HttpSession('127.0.0.1', 8080, function (action, ...)
  print('action:', action)
  if action == 'onHttp' then
    --- @type HttpSession, HttpProtocol, HttpProtocol
    local self, input, output = ...
    output.headers['connection'] = input.headers['connection']
    return output

  elseif action == 'onWebSocket' then
    --- @type HttpSession, WebSocketProtocol, WebSocketProtocol
    local self, input, output = ...
    print('onWebSocket:', input.payload)
  end

  return nil
end)

s:sendHandShake() -- Upgrade to websocket

local count = 1
local t1 = os.time()

while true do
  local t2 = os.time()
  s:resume() -- Polling

  if t2 - t1 > 5 then
    t1 = t2
    count = count + 1

    local request = WebSocketProtocol()
    request.mask = true
    request.opCode = WebSocketProtocol.OpCode.OP_TEXT
    request.payload = string.format("Hello <%d> times", count)
    s:send(request)
  end
end
```

#### HttpServerSession

> light.network.session.http_server_session -> HttpServerSession

There is also a fusion of HttpServerSession and WebSocketServerSession lol.

You can easily start a event-driven server with a callback like below:

```lua
local Log = require('light.Log')

local HttpServerSession = require('light.network.session.HttpServerSession')

local s = HttpServerSession('127.0.0.1', 3001, 200, function (action, ...)
  -- print('action:', action)
  if action == 'onHttp' then
    --- @type HttpSession, HttpProtocol, HttpProtocol
    local self, input, output = ...
    return output
  end

  return nil
end)

while true do
  s:resume() -- Polling
end
```

## Graphic

The graphics library requires you to additionally install Love2d and configure the environment.

Deployment method:

The least thought-provoking way is to directly download the non-installation version, unzip it, drag all the executable files and dlls inside to the root directory, and start it.

Run it: `D:\path...\love.exe .`

### Basic

#### Plane Vector

> light.graphics.Vector2

Includes `x` and `y` axis

#### 3D Vector

> light.graphics.Vector3

Includes `x`、 `y` and `z` axis

#### Quad Vector

> light.graphics.Vector4

Includes `x`、 `y`、 `z` and `w` axis

#### Font Management

> light.graphics.FontManager

To load fonts, and use fonts

- Load：`FontManager['font name'] = 'path/to/file.ttf'`
- Using：`local font = FontManager['font name'][12 size]`

#### UI Event

> light.graphics.Event

To bind UI view events, such as clicks `onMouseUp`

Interface `EventDelegate` is need to be implement

### Layers

#### Canvas Layer

> light.graphics.layer.CanvasLayer

Something like iOS `CALayer`，is used to painting

#### Image Layer

> light.graphics.layer.ImageLayer

Load your photo and pictures

#### Text Layer

> light.graphics.layer.TextLayer

Text layer that supports multi-color display:

`"#RI'm Red,#YI'm yellow"`

### Views (Control)

#### Button

> light.graphics.view.ButtonView

The button control

#### Label

> light.graphics.layer.LabelView

Label control, and its font can be set as you like

## Code Style Guide

### Variables

```lua
local var_name = 123 -- snake_case, good

local varName = 123 -- camelCase, normal
```

### Class / Type

```lua
-- Enumeration
local DataType = {
  TEXT,  
  NUMBER,
  TEXT_AND_NUMBER
}

local MyClass = {} -- CamelCase

function MyClass:new()
  self.dataSize = 123 -- CamelCase，object attributes
end

function MyClass:getData( ... ) -- camelCase，object methods
  -- body
end

function MyClass:StaticMethod( ... ) -- CamelCase, static method
  -- body
end

-- Static attribute
MyClass.DataType = DataType -- CamelCase
```

### Package (Namespace)

> Package or namespace is the folder directory

```
C:/name_space_a/name_space_b/...
```

#### Class

This is `MyClass.lua`:

```lua
local MyClass = {}

function MyClass:new( ... )
  -- body
end

return MyClass
```

#### Module

This is `my_module.lua`

```lua
local my_module = {}

my_module.TestCallA = function ( ... ) -- Utils should export, so CamelCase
  -- body
end

function my_module.TestCallB( ... ) -- Same
  -- body
end

return my_module
```

### Function

local function:

```lua
local function my_function() -- local, not export
  -- code
end

local function MyFunction() -- local, exprot
  -- code
end

return {
  MyFunction = MyFunction -- export
}
```

static global function：

```lua
function MyFunction()
  -- code
end
```

## License

This module is BSD-Licensed

Written by Jakit Liang
