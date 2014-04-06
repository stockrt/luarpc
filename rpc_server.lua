#!/usr/bin/env lua

-- Module.
local luarpc = require("luarpc")

-- Arguments.
if #arg < 1 then
  print("Usage: " .. arg[0] .. " <interface_file>")
  os.exit(1)
end
local interface_file = arg[1]

-- Objects.
local myobj1 = {
  foo = function (a, b, str)
    return a + b, "alo alo"
  end,
  boo = function (n)
    return n
  end,
  bar = function (n)
    return n + 1
  end,
  baz = function (str1, str2)
    return "echo str concat1: " .. str1 .. str2
  end,
  cha = function (c1, c2)
    return "echo char concat1: " .. c1 .. c2
  end,
}
local myobj2 = {
  foo = function (a, b, str)
    return a - b, "tchau"
  end,
  boo = function (n)
    return 1
  end,
  bar = function (n)
    return n - 1
  end,
  baz = function (str1, str2)
    return "echo str concat2: " .. str1 .. str2
  end,
  cha = function (c1, c2)
    return "echo char concat2: " .. c1 .. c2
  end,
}

-- server1/myobj1
local servant1 = luarpc.createServant(myobj1, interface_file)

-- server2/myobj2
local servant2 = luarpc.createServant(myobj2, interface_file)

-- Wait for clients.
luarpc.waitIncoming()
