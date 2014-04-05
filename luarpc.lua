-- http://www.inf.puc-rio.br/~noemi/sd-14/trab1.html

socket = require("socket")

local luarpc = {}
local server_list = {}
local client_list = {}

function luarpc.createServant(myobj, arq_interface)
  print("Setting up server " .. #server_list .. "...")

  -- tcp, bind, listen shortcut
  local server = socket.bind("*", 0, 2048)

  -- step by step
  -- local server = socket.tcp()
  -- server:bind("*", 0)
  -- server:listen(2048)

  -- options
  server:setoption('keepalive', true)
  server:setoption('linger', {on = false, timeout = 0})
  server:setoption('tcp-nodelay', true)
  server:settimeout(1) -- accept/send/receive timeout

  -- server list
  table.insert(server_list, server)
  -- table.foreach(server_list, print)

  -- info
  local ip, port = server:getsockname()
  print("Please connect on port " .. port)

  return server
end

function luarpc.waitIncoming()
  print("Waiting for clients...")
  -- table.foreach(server_list, print)

  while true do
    for i, server in pairs(server_list) do
      print("Server " .. i .. " " .. server)
      local client = server:accept()
      print("Client " .. client)

      -- client connected
      if client then
        -- options
        client:settimeout(10) -- send/receive timeout (line inactivity)

        -- client list
        table.insert(client_list, client)

        -- info
        local ip, port = client:getsockname()
        print("Client connected " .. client:getpeername() .. " client local port " .. port)
      end
    end

    -- sleep
    socket.select(nil, nil, 3)

    -- connected client sent some data
    client_recv_ready_list = socket.select(client_list, nil, 1)
    -- table.foreach(client_recv_ready_list, print)
    for i, client in pairs(client_recv_ready_list) do
      local line, err = client:receive("*l")
      if err then
        print("ERROR: " .. err)
      else
        print("LINE: " .. line)
      end
      client:close()
    end
  end
end

function luarpc.createProxy()
end

function createrpcproxy(hostname, port, interface)
    local functions = {}
    local prototypes = parser(interface)
    for name, sig in pairs(prototypes) do
        functions[name] = function(...)
            -- validating params
            local params = {...}
            local values = {name}
            local types = sig.input
            for i=1, #types do
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
