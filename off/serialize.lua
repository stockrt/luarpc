-- http://help.interfaceware.com/kb/112

function SaveTable(Table)
  local savedTables = {} -- Used to record tables that have been saved, so that we do not go into an infinite recursion.
  local outFuncs = {
    ["string"] = function(value) return string.format("%q", value) end
    ["boolean"] = function(value) if (value) then return "true" else return "false" end end
    ["number"] = function(value) return string.format("%f", value) end
  }
  local outFuncsMeta = {
    __index = function(t, k) error("Invalid Type For SaveTable: " .. k) end
  }
  setmetatable(outFuncs, outFuncsMeta)
  local tableOut = function(value)
    if (savedTables[value]) then
      error("There is a cyclical reference (table value referencing another table value) in this set.")
    end
    local outValue = function(value) return outFuncs[type(value)](value) end
    local out = "{"
    for i, v in pairs(value) do out = out .. "[" .. outValue(i) .. "]=" .. outValue(v) .. ";" end
    savedTables[value] = true -- Record that it has already been saved.
    return out .. "}"
  end
  outFuncs["table"] = tableOut
  return tableOut(Table)
end

function LoadTable(Input)
  -- Note that this does not enforce anything, for simplicity.
  return assert(loadstring("return " .. Input))()
end
