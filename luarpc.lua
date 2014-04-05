local luarpc = {}

function luarpc.createServant()
  print("luarpc.createServant")
end

function luarpc.waitIncoming()
  print("luarpc.waitIncoming")
end

function luarpc.createProxy()
  print("luarpc.createProxy")
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
