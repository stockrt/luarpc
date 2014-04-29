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
