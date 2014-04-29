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
local proxy1 = luarpc.createProxy(server_address, server_port1, interface_file)
local proxy2 = luarpc.createProxy(server_address, server_port2, interface_file)


-- proxy1/obj1
print()
print()
print("###################################################################")
print("- Proxy1")
print("###################################################################")
print()

local result, msg = proxy1.foo(5, 3)
print("* Result: " .. result .. " / Msg: " .. msg)

local result = proxy1.boo(20)
print("* Echo: " .. result)


-- proxy2/obj2
print()
print()
print("###################################################################")
print("- Proxy2")
print("###################################################################")
print()

local result, msg = proxy2.foo(5, 3)
print("* Result: " .. result .. " / Msg: " .. msg)

local result = proxy2.boo(20)
print("* Fixed: " .. result)
