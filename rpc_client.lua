#!/usr/bin/env lua

local luarpc = require("luarpc")

local arq_interface = "interface.lua"

local proxy1 = luarpc.createproxy (IP, porta1, arq_interface)
local proxy2 = luarpc.createproxy (IP, porta2, arq_interface)
local r, s = proxy1.foo(3, 5)
local t = proxy2.boo(10)
