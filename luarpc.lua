-- http://www.inf.puc-rio.br/~noemi/sd-14/trab1.html

socket = require("socket")

local luarpc = {}
local servant_list = {}

function luarpc.createServant()
  local serv = assert(socket.bind("*", 0))
  table.insert(servant_list, serv)
  -- table.foreach(servant_list, print)
  local ip, port = serv:getsockname()
  print("Please connect on port " .. port)
  return serv
end

function luarpc.waitIncoming()
  print("Waiting for clients...")
  -- table.foreach(servant_list, print)
  -- socket.select(servant_list)
end

function luarpc.createProxy()
end

function createrpcproxy(hostname, port, interface)
    local functions = {}
    local prototypes = parser(interface)
    for name,sig in pairs(prototypes) do
        functions[name] = function(...)
            -- validating params
            local params = {...}
            local values = {name}
            local types = sig.input
            for i=1,#types do
                if (#params >= i) then
                    values[#values+1] = params[i]
                    if (type(params[i])~="number") then
                        values[#values] = "\"" .. values[#values] .. "\""
                    end
                end
                -- creating request
                local request = pack(values)
                -- creating socket
                local client = socket.tcp()
                local conn = client:connect(hostname, port)
                local result = client:send(request .. '\n')
            end
        end
        return functions;
    end
end

return luarpc
