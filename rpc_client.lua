#!/usr/bin/env lua

local luarpc = require("luarpc")

local arq_interface = "interface.lua"

local proxy1 = luarpc.createproxy(server_ip, server_port, arq_interface)
local proxy2 = luarpc.createproxy(server_ip, server_port, arq_interface)

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
