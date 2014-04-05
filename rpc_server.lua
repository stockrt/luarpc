#!/usr/bin/env lua

local luarpc = require("luarpc")

local arq_interface = "interface.lua"

local myobj1 = {
  foo = function (a, b, s)
    return a+b, "alo alo"
  end,
  boo = function (n)
    return n
  end
}

local myobj2 = {
  foo = function (a, b, s)
    return a-b, "tchau"
  end,
  boo = function (n)
    return 1
  end
}

local server1 = luarpc.createServant (myobj1, arq_interface)
local server2 = luarpc.createServant (myobj2, arq_interface)
luarpc.waitIncoming()
