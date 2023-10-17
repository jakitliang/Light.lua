# 灯.lua

> 若我即是彼方，光明坦荡

`灯` 的目标是 Lua 的通用标准库，一体化设计，类似于 C++ 的 STL，为 Lua 开发者们提供基础设施。

### 简介

`灯` 目前有 6 个模块：

- **对象** 提供面向原型的编程基础类
- **记录** 提供 ORM 基础能力
- **协作** 提供协程与事件机
- **日志** 提供基本日志输出
- **套接** 提供跨平台的套接字功能，与少量加解密方法。
- **网络** 提供 Http 与 WebSocket 网络通信能力，和 TCP 基础能力。

## 对象

> light.object -> Object

以最适合 Lua 语言的链式结构设计，提供高性能的方法调用与 JavaScript 同类特征特性。

示例代码：

```lua
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

## 记录

> light.record -> Record

记录是 数据库的 ORM 模块，充当 MVC / MVVM 当中 Model 的角色

使用 Record 即可获得跟 `SQLAlchemy` 或 `ActiveRecord` 同等特性。

示例代码：

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

### 设备

> light.device -> Device

设备提供可扩展性的接口，方便用户接入其它数据存储 DBC 接口实现为驱动

## 协作

> light.worker -> Worker

以 `Lua` 协程 `rotoutine` 为基础结合 `对象.lua` 实现的接口类

用户可

### 事件机

> light.worker.event_worker -> EventWorker

以跨平台套接字 `light.socket` 结合 **协程** 实现的协作类。

等同于 `libevent` 和 `libuv`，提供用于 IO 异步事件处理。

## 日志

> light.log -> Log

示例代码：

```lua
Log.level = Log.Level.DEBUG

Log:info('Hi,', 'here is themessage')
Log:warningF('warning %d', 123)
Log:error('error')
Log:debug('debug')
```

## 套接

提供跨平台的套接字支持：

- Windows
- Linux
- macOS
- iOS

### TCP

> light.socket.TCP -> TCP

示例代码：

```lua
local s = light.socket.TCP()
s:connect('localhost', 8080)
```

### UDP

> light.socket.UDP -> UDP

**尽快提供 UDP 方面的支持**

### Base64

#### 加密

> light.socket.base64encode -> fun(string)

#### 解密

> light.socket.base64decode -> fun(string)

### SHA1

> light.socket.sha1 -> fun(string)

### SHA1Hex

> light.socket.sha1hex -> fun(string)

## 网络

### 频道

#### TCP 频道

> light.network.channel.tcp_channel -> TCPChannel

TCP 频道为最基本的 TCP 消息发送管道，用户可通过下列方式操作：

- TCPChannel:connect('host', port)
- TCPChannel:connectNow('host', port) -- 非阻塞连接
- TCPChannel:read(1024)
- TCPChannel:readNow(1024) - 非阻塞读
- TCPChannel:write('buffer', 6)
- TCPChannel:writeNow('buffer', 6) - 非阻塞写
- TCPChannel:close()

#### TCP 服务频道

> light.network.channel.tcp_server_channel -> TCPServerChannel

TCP 频道为 TCP 服务类应用的管道，用户可通过下列方式操作：

- TCPChannel:accept()
- TCPChannel:acceptNow() -- 非阻塞接纳
- TCPChannel:close()

### 协议

> light.protocol

基于状态机的数据交换协议分析接口，支持 **序列化** 以及 **反序列化**

#### HTTP 1.1 协议

> light.network.protocol.http_protocol -> HttpProtocol

按 Http 1.1 协议标准实现，提供状态信息属性：

- statusCode
- statusMessage
- method
- path
- headers
- content

提供 MIME 类：

> HttpProtocol.MIME

#### WebSocket 13 协议

> light.network.protocol.websocket_protocol -> WebsocketProtocol

按 WebSocket 13 协议标准实现，提供状态信息属性：

- fin
- mask
- masking -- 掩码
- length
- payload -- 消息主体
- ...

### 会话

会话使用 **基于协程** 的 **事件机** 实现 IO 异步，并提供委托 `delegate` 接口与 函数接口便于用户使用。

#### TCP 会话

> light.network.session.tcp_session -> TCPSession

#### TCP 服务会话

> light.network.session.tcp_server_session -> TCPServerSession

#### Http WebSocket 聚合会话

> light.network.session.http_session -> HttpSession

提供 Http 与 WebSocket 聚合的客户端类

用户可直接使用，通过设置委托 `delegate` 回调即可快速建立 **基于事件** 的客户端应用

示例代码：

```lua
local HttpSession = require('light.network.session.http_session')
local WebSocketProtocol = require('light.network.protocol.websocket_protocol')

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

#### Http WebSocket 聚合服务会话

> light.network.session.http_server_session -> HttpServerSession

使用 Http WebSocket 聚合服务会话可快速开发 高性能后端类 应用。

示例代码：

```lua
local Log = require('light.log')

local HttpServerSession = require('light.network.session.http_server_session')

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

## 版权

此模块以 `BSD 2-Clause License` 协议发行，请遵守规矩！

著作权归 **Jakit Liang 泊凛** 所有
