#!/usr/bin/env lua

-- Module.
local luarpc = require("luarpc")
require("tableser")

-- Arguments.
if #arg < 1 then
  print("Usage: " .. arg[0] .. " <interface_file> [server_port1] [server_port2] [pool_size]")
  os.exit(1)
end
local interface_file = arg[1]
local server_port1 = arg[2]
local server_port2 = arg[3]
local pool_size = tonumber(arg[4])

-- Objects.
local obj1 = {
  foo = function (a, b, str)
    return a + b, "alo alo"
  end,
  oid = function ()
    return nil
  end,
  min = function (str)
    return 1
  end,
  men = function (n)
    return n
  end,
  tbl = function (str)
    return 0
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
  hello = function (str)
    return "Greetings from obj1, " .. str .. "!"
  end,
  capabilities = function ()
    local caps = ""
    for rpc_method, method in pairs(myinterface.methods) do
      local cap = method.resulttype .. " " .. rpc_method .. "("
      for _, param in pairs(method.args) do
        if param.direction == "in" or param.direction == "inout" then
          cap = cap .. param.type .. ", "
        end
      end
      -- Removes the last ", " and appends ")" for method termination.
      cap = cap:gsub(", $", "") .. ")"
      -- Each capability goes in a new line.
      caps = caps .. cap .. "\n"
    end
    -- Removes the last "\n" capability separator.
    caps = caps:gsub("\n$", "")
    return caps
  end,
}

local obj2 = {
  foo = function (a, b, str)
    return a - b, "tchau"
  end,
  oid = function ()
    return nil
  end,
  min = function (str)
    return 1
  end,
  men = function (n)
    return n
  end,
  tbl = function (str)
    local x = LoadTable(str)
    return 1
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
  hello = function (str)
    return "Greetings from obj2, " .. str .. "!"
  end,
  capabilities = function ()
    -- TODO: Extra results and types.
    local caps = ""
    for rpc_method, method in pairs(myinterface.methods) do
      local cap = method.resulttype .. " " .. rpc_method .. "("
      for _, param in pairs(method.args) do
        if param.direction == "in" or param.direction == "inout" then
          cap = cap .. param.type .. ", "
        end
      end
      -- Removes the last ", " and appends ")" for method termination.
      cap = cap:gsub(", $", "") .. ")"
      -- Each capability is separated by "  |  ".
      caps = caps .. cap .. "  |  "
    end
    -- Removes the last " | " capability separator.
    caps = caps:gsub("  |  $", "")
    return caps
  end,
}

-- server1/obj1
local servant1 = luarpc.createServant(obj1, interface_file, server_port1, pool_size)
-- local servant11 = luarpc.createServant(obj1, interface_file)

-- server2/obj2
local servant2 = luarpc.createServant(obj2, interface_file, server_port2, pool_size)
-- local servant21 = luarpc.createServant(obj2, interface_file)

-- Wait for clients.
luarpc.waitIncoming()
