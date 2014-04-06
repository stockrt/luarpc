#!/usr/bin/env lua

-- Module.
local luarpc = require("luarpc")

-- Arguments.
if #arg < 4 then
  print("Usage: " .. arg[0] .. " <interface_file> <server_address> <server_port1> <server_port2>")
  os.exit(1)
end
local interface_file = arg[1]
local server_address = arg[2]
local server_port1 = arg[3]
local server_port2 = arg[4]

-- Proxies.
local proxy1 = luarpc.createproxy(server_address, server_port1, interface_file)
local proxy2 = luarpc.createproxy(server_address, server_port2, interface_file)

-- proxy1/myobj1
print("Proxy1")

local result, msg = proxy1.foo(5, 3)
print("Result: " .. result .. " / Msg: " .. msg)

local result = proxy1.boo(20)
print("Echo: " .. result)

local result = proxy1.boo(30)
print("Echo: " .. result)

local result = proxy1.bar("tipo errado")
print("Err: " .. result)

local result = proxy1.bar("quantia errada", "tudo errado")
print("Err: " .. result)

local result = proxy1.baz("abc", "def")
print("Concat1: " .. result)

local result = proxy1.nodef("nao existe")
print("Err: " .. result)

print()

-- proxy2/myobj2
print("Proxy2")

local result, msg = proxy2.foo(5, 3)
print("Result: " .. result .. " / Msg: " .. msg)

local result = proxy2.boo(20)
print("Fixed: " .. result)

local result = proxy2.boo(30)
print("Fixed: " .. result)

local result = proxy2.bar("tipo errado")
print("Err: " .. result)

local result = proxy2.bar("quantia errada", "tudo errado")
print("Err: " .. result)

local result = proxy2.baz("abc", "def")
print("Concat2: " .. result)

local result = proxy2.nodef("nao existe")
print("Err: " .. result)
