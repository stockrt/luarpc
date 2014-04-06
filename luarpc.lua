-- http://www.inf.puc-rio.br/~noemi/sd-14/trab1.html

local socket = require("socket")

-- This is the main module luarpc.
local luarpc = {}

local servant_list = {} -- {server, obj, iface, client_list}
myinterface = {}

function interface(iface)
  -- Global namespace.
  myinterface = iface
end

function validate_type(value, param_type)
  if param_type == "char" then
    if #value == 1 then
      return true
    end
  elseif param_type == "string" then
    if tostring(value) then
      return true
    end
  elseif param_type == "double" then
    if tonumber(value) then
      return true
    end
  elseif param_type == "void" then
    if value == "" or value == "\n" then
      return true
    end
  end

  return false
end

function luarpc.createServant(myobj, interface_file)
  print("Setting up servant " .. #servant_list .. "...")

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

  -- Interface.
  dofile(interface_file)

  -- Servant.
  local servant = {
    server = server,
    obj = myobj,
    iface = myinterface,
    client_list = {},
  }

  -- Servant list.
  table.insert(servant_list, servant)

  -- Info.
  local ip, port = server:getsockname()
  print("Please connect on port " .. port)
  print()

  return servant
end

function luarpc.waitIncoming()
  print("Waiting for clients...")

  -- Jump on protocol errors.
  local skip = false

  while true do
    for _, servant in pairs(servant_list) do
      -- Wait for new client connection on this servant.
      -- Wait for connection just a few ms.
      local client = servant.server:accept()

      -- Client connected.
      if client then
        -- Options.
        client:settimeout(10) -- send/receive timeout (line inactivity).

        -- Client list.
        table.insert(servant.client_list, client)

        -- Info.
        local ip, port = client:getsockname()
        print("Client connected " .. client:getpeername() .. " on port " .. port)
      end

      -- Connected client sent some data for this servant.
      -- Wait for activity just a few ms.
      local client_recv_ready_list, _, err = socket.select(servant.client_list, nil, 0.1)
      for _, client in pairs(client_recv_ready_list) do
        skip = false

        if type(client) ~= "number" then
          -- Info.
          local ip, port = client:getsockname()
          print("Receiving data from client " .. client:getpeername() .. " on port " .. port)

          -- Method receive.
          print("Receiving method...")
          local rpc_method, err = client:receive("*l")
          if err then
            local err_msg = "___ERRORPC: Receiving method from client: " .. err
            print(err_msg)
            local _, err = client:send(err_msg)
            if err then
              print("ERROR: Sending client ___ERRORPC notification: \"" .. err_msg .. "\": " .. err)
            end
            break
          else
            print("< rpc_method: " .. rpc_method)
          end

          -- Validate method.
          if servant.iface.methods[rpc_method] then
            -- Parameters receive.
            local values = {}
            for _, param in pairs(servant.iface.methods[rpc_method].args) do
              if param.direction == "in" or param.direction == "inout" then
                print("Receiving value...")
                local value, err = client:receive("*l")
                if err then
                  local err_msg = "___ERRORPC: Receiving value from client: " .. err
                  print(err_msg)
                  local _, err = client:send(err_msg)
                  if err then
                    print("ERROR: Sending client ___ERRORPC notification: \"" .. err_msg .. "\": " .. err)
                  end
                  skip = true
                  break
                else
                  -- Validate type.
                  if not validate_type(value, param.type) then
                    local err_msg = "___ERRORPC: Wrong type for value \"" .. value .. "\" expecting type \"" .. param.type .. "\""
                    print(err_msg)
                    local _, err = client:send(err_msg)
                    if err then
                      print("ERROR: Sending client ___ERRORPC notification: \"" .. err_msg .. "\": " .. err)
                    end
                    skip = true
                    break
                  end

                  -- Method params.
                  print("< value: " .. value)
                  table.insert(values, value)
                end
              end
            end

            -- Call method on server.
            if not skip then
              local status, result = pcall(servant.obj[rpc_method], unpack(values))
              if not status then
                local err_msg = "___ERRORPC: Problem calling method \"" .. rpc_method .. "\""
                print(err_msg)
                local _, err = client:send(err_msg)
                if err then
                  print("ERROR: Sending client ___ERRORPC notification: \"" .. err_msg .. "\": " .. err)
                end
              else
                print("= result: " .. result)
                -- Return result to client.
                local _, err = client:send(result)
                if err then
                  print("ERROR: Sending client the result \"" .. result .. "\": " .. err)
                end
              end
            end
          else
            local err_msg = "___ERRORPC: Invalid method \"" .. rpc_method .. "\""
            print(err_msg)
            local _, err = client:send(err_msg)
            if err then
              print("ERROR: Sending client ___ERRORPC notification: \"" .. err_msg .. "\": " .. err)
            end
          end

          -- Terminate connection.
          client:close()
        end
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
