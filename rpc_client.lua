#!/usr/bin/env lua

local luarpc = require("luarpc")

local p1 = luarpc.createproxy (IP, porta1, arq_interface)
local p2 = luarpc.createproxy (IP, porta2, arq_interface)
local r, s = p1.foo(3, 5)
local t = p2.boo(10)
