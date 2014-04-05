-- http://www.inf.puc-rio.br/~noemi/sd-14/trab1.html

local socket = require("socket")

-- This is the main module luarpc.
local luarpc = {}

local server_list = {}
local client_list = {}

function luarpc.createServant(myobj, interface_file)
  print("Setting up server " .. #server_list .. "...")

  -- tcp, bind, listen shortcut.
  local server = socket.bind("*", 0, 2048)

  -- Step by step.
  -- local server = socket.tcp()
  -- server:bind("*", 0)
  -- server:listen(2048)

  -- Options.
  server:setoption('keepalive', true)
  server:setoption('linger', {on = false, timeout = 0})
  server:setoption('tcp-nodelay', true)
  server:settimeout(0.1) -- accept/send/receive timeout

  -- Server list.
  table.insert(server_list, server)
  -- table.foreach(server_list, print)

  -- Info.
  local ip, port = server:getsockname()
  print("Please connect on port " .. port)
  print()

  return server
end

function luarpc.waitIncoming()
  print("Waiting for clients...")
  -- table.foreach(server_list, print)

  while true do
    for i, server in pairs(server_list) do
      -- print("Server " .. i .. " waiting for a client...")
      local client = server:accept()

      -- Client connected.
      if client then
        -- Options.
        client:settimeout(10) -- send/receive timeout (line inactivity).

        -- Client list.
        table.insert(client_list, client)

        -- Info.
        local ip, port = client:getsockname()
        print("Client connected " .. client:getpeername() .. " on port " .. port)
      end
    end

    -- Connected client sent some data.
    -- print("Waiting for any client activity...")
    local client_recv_ready_list, client_send_ready_list, err = socket.select(client_list, nil, 0.1)
    for i, client in pairs(client_recv_ready_list) do
      if type(client) ~= "number" then
        local ip, port = client:getsockname()
        print("Receiving data from client " .. client:getpeername() .. " on port " .. port)
        local line, err = client:receive("*l")
        if err then
          print("ERROR: " .. err)
        else
          print("< " .. line)
        end
        client:close()
      end
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
