#!/usr/bin/env lua

-- Module.
local luarpc = require("luarpc")

-- Arguments.
if #arg < 3 then
  print("Usage: " .. arg[0] .. " <interface_file> <server_address> <server_port>")
  os.exit(1)
end
local interface_file = arg[1]
local server_ip = arg[2]
local server_port = arg[3]

-- Proxies.
local proxy1 = luarpc.createproxy(server_ip, server_port, interface_file)
local proxy2 = luarpc.createproxy(server_ip, server_port, interface_file)

-- proxy1/myobj1
local sum, str = proxy1.foo(5, 3)
print(sum)
print(str)
local res = proxy1.boo(20)
print("echo " .. res)

-- proxy2/myobj2
local sub, str = proxy2.foo(5, 3)
print(sub)
print(str)
local res = proxy2.boo(20)
print("fixed " .. res)
