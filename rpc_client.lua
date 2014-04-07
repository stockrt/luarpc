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
print("- Proxy1")

local result = proxy1.foo(5, 3)
print("Result: " .. result)

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

local result = proxy1.baz("multiline1\nmultiline2\ncom escape indicado o barran \\n na mesma linha", ".")
print("Concat1: " .. result)

local result = proxy1.cha("a", "b")
print("Str: " .. result)

local result = proxy1.cha("abc", 123)
print("Err: " .. result)

local result = proxy1.naodefinido("nao existe")
print("Err: " .. result)

local result = proxy1.hello("Rogerio proxy1")
print("Greet: " .. result)

local result = proxy1.capabilities()
print("Cap: " .. result)

local result = proxy1.hello()
print("Err: " .. result)

local result = proxy1.capabilities("nao deveria passar param")
print("Err: " .. result)

local result = proxy1.capabilities(1, 2)
print("Err: " .. result)

local result = proxy1.capabilities(1)
print("Err: " .. result)

-- proxy2/obj2
print()
print("- Proxy2")

local result = proxy2.foo(5, 3)
print("Result: " .. result)

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

x = [[multiline1
multiline2
com escape indicado o barran \n na mesma linha]]
local result = proxy2.baz(x, ".")
print("Concat2: " .. result)

local result = proxy2.cha("1", "2")
print("Str: " .. result)

local result = proxy2.cha(1, 2)
print("Err: " .. result)

local result = proxy2.naodefinido("nao existe")
print("Err: " .. result)

local result = proxy2.hello("Rogerio proxy2")
print("Greet: " .. result)

local result = proxy2.capabilities()
print("Cap: " .. result)

local result = proxy2.hello()
print("Err: " .. result)

local result = proxy2.capabilities("nao deveria passar param")
print("Err: " .. result)

local result = proxy2.capabilities(1, 2)
print("Err: " .. result)

local result = proxy2.capabilities(1)
print("Err: " .. result)
