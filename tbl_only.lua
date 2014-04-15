#!/usr/bin/env lua

-- Module.
require("tableser")

-- Arguments.
if #arg < 1 then
  print("Usage: " .. arg[0] .. " <runs>")
  os.exit(1)
end
local runs = tonumber(arg[1])



-- Table serialize/deserialize local.
local t = {}
for i = 1, 100 do
  local x = "x" .. i
  t[x] = 3.1415 + i
end
print()
print("+ Table with 100 doubles")
for k, v in pairs(t) do print("- " .. k .. " " .. v) end

local enc = SaveTable(t)

-- Serialize.
tini = os.time()
for x = 1, runs do
  local result = SaveTable(t)
end
tend = os.time()
local res = "tbl_only serialize took " .. os.difftime(tend, tini) .. " seconds for " .. runs .. " runs"
print(res)

-- Deserialize.
tini = os.time()
for x = 1, runs do
  local dresult = LoadTable(enc)
end
tend = os.time()
local res = "tbl_only deserialize took " .. os.difftime(tend, tini) .. " seconds for " .. runs .. " runs"
print(res)

-- Serialize/Deserialize.
tini = os.time()
for x = 1, runs do
  local result = SaveTable(t)
  local dresult = LoadTable(result)
end
tend = os.time()
local res = "tbl_only serialize/deserialize took " .. os.difftime(tend, tini) .. " seconds for " .. runs .. " runs"
print(res)
