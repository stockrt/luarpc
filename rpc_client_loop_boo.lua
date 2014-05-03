#!/usr/bin/env lua

-- Module.
local luarpc = require("luarpc")

-- Arguments.
if #arg < 4 then
  print("Usage: " .. arg[0] .. " <interface_file> <server_address> <server_port> <run_seconds>")
  os.exit(1)
end
local interface_file = arg[1]
local server_address = arg[2]
local server_port = arg[3]
local run_seconds = tonumber(arg[4])


-- Proxy.
local proxy = luarpc.createProxy(server_address, server_port, interface_file)


-- 1 byte de ida + nome do método = 4 bytes
-- 1 byte de volta + nil do result padrão = 4 bytes
-- Total de 8 bytes por chamada.
local calls = 0
local tini = os.time()
while os.difftime(os.time(), tini) < run_seconds do
  local result = proxy.boo(1)
  calls = calls + 1
end
local res = "boo calls " .. calls .. " in ".. run_seconds .. " seconds for server " .. server_port
print(res)
local file_name = "report/runs/boo.txt"
local file_handler = io.open(file_name, "a+")
file_handler:write("\n\n" .. res .. "\n")
file_handler:close()
