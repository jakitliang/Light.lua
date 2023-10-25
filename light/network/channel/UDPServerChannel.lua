--- Light.lua
--- Light up your way to the internet
--- @module 'UDPChannel'
--- @author Jakit Liang 泊凛
--- @date 2023-10-16
--- @license MIT

local Object = require('light.Object')
local socket = require('light.socket')
local EventWorker = require('light.worker.EventWorker')
local UDPChannel = require('light.network.channel.UDPChannel')
local Log = require('light.Log')

local UDPServerChannel = {}

local UDPServerChannelDelegate = Object()
UDPServerChannelDelegate:extends(UDPChannel.Delegate)

local function UDPServerChannelInitIO(self, host, port)
  local io = socket.UDP()

  io:bind(host, port)

  return io
end

function UDPServerChannel:new(host, port, delegate, io)
  io = io or UDPServerChannelInitIO(self, host, port)
  UDPChannel.new(self, host, port, delegate, io)
end

Object(UDPChannel, UDPServerChannel)

UDPServerChannel.Delegate = UDPServerChannelDelegate

return UDPServerChannel
