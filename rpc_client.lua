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
local sum, str = proxy1.foo(5, 3)
print(sum)
print(str)
local res = proxy1.boo(20)
print("echo " .. res)
local res = proxy1.baz("nao existe")
print("err " .. res)

print()

-- proxy2/myobj2
print("Proxy2")
local sub, str = proxy2.foo(5, 3)
print(sub)
print(str)
local res = proxy2.boo(20)
print("fixed " .. res)
local res = proxy2.baz("nao existe")
print("err " .. res)
