#!/usr/bin/env lua

-- Module.
local luarpc = require("luarpc")
require("tableser")

-- Arguments.
if #arg < 4 then
  print("Usage: " .. arg[0] .. " <interface_file> <server_address> <server_port> <runs>")
  os.exit(1)
end
local interface_file = arg[1]
local server_address = arg[2]
local server_port = arg[3]
local runs = tonumber(arg[4])


-- Proxy.
local proxy = luarpc.createProxy(server_address, server_port, interface_file)


-- Operação matemática simples, com um retorno numérico e um string pequeno.
local result, msg = proxy.foo(5, 3)
print(result)
print(msg)

os.execute("./stats-zero.sh")
tini = os.time()
for x = 1, runs do
  local result, msg = proxy.foo(5, 3)
end
tend = os.time()
local res = "foo took " .. os.difftime(tend, tini) .. " seconds for server " .. server_port .. " for " .. runs .. " runs"
print(res)
local file_name = "report/runs/foo.txt"
local file_handler = io.open(file_name, "a+")
file_handler:write("\n\n" .. res .. "\n")
file_handler:close()
os.execute("./stats-collect.sh >> " .. file_name)


-- Void nos dois sentidos. "nil" e "nil".
local result = proxy.oid()
print(result)

os.execute("./stats-zero.sh")
tini = os.time()
for x = 1, runs do
  local result = proxy.oid()
end
tend = os.time()
local res = "oid took " .. os.difftime(tend, tini) .. " seconds for server " .. server_port .. " for " .. runs .. " runs"
print(res)
local file_name = "report/runs/oid.txt"
local file_handler = io.open(file_name, "a+")
file_handler:write("\n\n" .. res .. "\n")
file_handler:close()
os.execute("./stats-collect.sh >> " .. file_name)


-- 1 byte de ida e 1 byte de volta + encoding com wrapping de string "".
-- Total 3 bytes de ida e 3 bytes de volta.
local result = proxy.min("R")
print(result)

os.execute("./stats-zero.sh")
tini = os.time()
for x = 1, runs do
  local result = proxy.min("R")
end
tend = os.time()
local res = "min took " .. os.difftime(tend, tini) .. " seconds for server " .. server_port .. " for " .. runs .. " runs"
print(res)
local file_name = "report/runs/min.txt"
local file_handler = io.open(file_name, "a+")
file_handler:write("\n\n" .. res .. "\n")
file_handler:close()
os.execute("./stats-collect.sh >> " .. file_name)


-- 10240 bytes de ida e 10240 bytes de volta.
local result = proxy.min(string.rep("R", 10240))
print(result)

os.execute("./stats-zero.sh")
tini = os.time()
for x = 1, runs do
  local result = proxy.min(string.rep("R", 10240))
end
tend = os.time()
local res = "min 10KB took " .. os.difftime(tend, tini) .. " seconds for server " .. server_port .. " for " .. runs .. " runs"
print(res)
local file_name = "report/runs/min10kb.txt"
local file_handler = io.open(file_name, "a+")
file_handler:write("\n\n" .. res .. "\n")
file_handler:close()
os.execute("./stats-collect.sh >> " .. file_name)


-- Requer o mínimo de tráfego de rede. É melhor do que void pois em nosso
-- protocolo o void significa "nil" (5 bytes), já este double significa 1
-- (apenas 1 byte).
local result = proxy.men(1)
print(result)

os.execute("./stats-zero.sh")
tini = os.time()
for x = 1, runs do
  local result = proxy.men(1)
end
tend = os.time()
local res = "men took " .. os.difftime(tend, tini) .. " seconds for server " .. server_port .. " for " .. runs .. " runs"
print(res)
local file_name = "report/runs/men.txt"
local file_handler = io.open(file_name, "a+")
file_handler:write("\n\n" .. res .. "\n")
file_handler:close()
os.execute("./stats-collect.sh >> " .. file_name)


-- Table serialize. Em um rpc_server a tabela não é deserializada, em outro ela
-- é deserializada.
local t = {}
for i = 1, 100 do
  local x = "x" .. i
  t[x] = 3.1415 + i
end
print()
print("+ Table with 100 doubles")
for k, v in pairs(t) do print("- " .. k .. " " .. v) end

local result = proxy.tbl(SaveTable(t))
print(result)

os.execute("./stats-zero.sh")
tini = os.time()
for x = 1, runs do
  local result = proxy.tbl(SaveTable(t))
end
tend = os.time()
local res = "tbl took " .. os.difftime(tend, tini) .. " seconds for server " .. server_port .. " for " .. runs .. " runs"
print(res)
local file_name = "report/runs/tbl.txt"
local file_handler = io.open(file_name, "a+")
file_handler:write("\n\n" .. res .. "\n")
file_handler:close()
os.execute("./stats-collect.sh >> " .. file_name)
