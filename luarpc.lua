-- http://www.inf.puc-rio.br/~noemi/sd-14/trab1.html

--[[
TODO:
- Do ponto de vista de engenharia, algumas chamadas poderiam ser encapsuladas para termos menos linhas de código e menos repetição;

- Como fazer para retornar __ERRORPC se o cliente espera um double e valida retorno?
O protocolo é baseado na troca de strings ascii. Cada chamada é realizada pelo nome do método seguido da lista de parâmetros in. Entre o nome do método e o primeiro argumento, assim como depois de cada argumento, deve vir um fim de linha. A resposta deve conter o valor resultante seguido dos valores dos argumentos de saída, cada um em uma linha. Caso ocorra algum erro na execução da chamada, o servidor deve responder com uma string iniciada com "___ERRORPC: ", possivelmente seguida de uma descrição mais específica do erro (por exemplo, "função inexistente").
]]

local socket = require("socket")
local unpack = unpack or table.unpack

-- This is the main module luarpc.
local luarpc = {}

-- Lists.
local servant_list = {} -- {server, obj, iface, client_list}

-- Global namespace.
myinterface = {}

function interface(iface)
  -- Global namespace.
  myinterface = iface
end

function luarpc.validate_type(param_type, value)
  if param_type == "char" then
    if #tostring(value) == 1 then
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
    if value == "" then
      return true
    end
  end

  return false
end

--[[
20.3 – Captures
http://www.lua.org/pil/20.3.html

20.4 – Tricks of the Trade
http://www.lua.org/pil/20.4.html

    function code (s)
      return (string.gsub(s, "\\(.)", function (x)
                return string.format("\\%03d", string.byte(x))
              end))
    end

    function decode (s)
      return (string.gsub(s, "\\(%d%d%d)", function (d)
                return "\\" .. string.char(d)
              end))
    end
]]

function luarpc.encode(param_type, value)
  if param_type == "string" then
    local x = "XXXXXXXXXX"
    local str = value:gsub("\n", x)
    str = str:gsub("\\", "\\\\")
    str = str:gsub(x, "\\n")
    return str
  else
    return tostring(value)
  end
end

function luarpc.decode(param_type, value)
  if param_type == "string" then
    local x = "XXXXXXXXXX"
    local str = value:gsub("\\n", x)
    str = str:gsub("\\\\", "\\")
    str = str:gsub(x, "\n")
    return str
  elseif param_type == "double" then
    if tonumber(value) then
      return tonumber(value)
    end
  end

  return value
end

function luarpc.createServant(obj, interface_file, server_port)
  print("Setting up servant " .. #servant_list + 1 .. "...")

  -- Dynamic or static port.
  local s_port = 0
  if server_port then
    s_port = server_port
  end

  -- tcp, bind, listen shortcut.
  local server, err = socket.bind("*", s_port, 2048)
  if err then
    local err_msg = "___ERRONET: Server could not bind: " .. err
    print(err_msg)
    return err_msg
  end

  -- Step by step.
  -- local server = socket.tcp()
  -- server:bind("*", s_port)
  -- server:listen(2048)

  -- Connection options.
  server:setoption("keepalive", true)
  server:setoption("linger", {on = false, timeout = 0})
  server:setoption("tcp-nodelay", true)
  server:settimeout(0.1) -- accept/send/receive timeout

  -- Interface.
  dofile(interface_file)

  -- Servant.
  local servant = {
    server = server,
    obj = obj,
    iface = myinterface,
    client_list = {},
  }

  -- Servant list.
  table.insert(servant_list, servant)

  -- Connection info.
  local ip, port = server:getsockname()
  local port_file = "port" .. #servant_list .. ".txt"
  local file = io.open(port_file, "w")
  file:write(port .. "\n")
  file:close()
  print("Please connect on port " .. port .. " (also, you can script clients reading port number from file " .. port_file .. ")")
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
        -- Connection options.
        client:settimeout(10) -- send/receive timeout (line inactivity).

        -- Client list.
        table.insert(servant.client_list, client)

        -- Connection info.
        local ip, port = client:getsockname()
        print("Client connected " .. client:getpeername() .. " on port " .. port)
      end

      -- Connected client sent some data for this servant.
      -- Wait for activity just a few ms.
      local client_recv_ready_list, _, err = socket.select(servant.client_list, nil, 0.1)
      for _, client in pairs(client_recv_ready_list) do
        skip = false

        if type(client) ~= "number" then
          -- Connection info.
          local ip, port = client:getsockname()
          print("Receiving request data from client " .. client:getpeername() .. " on port " .. port)

          -- Method receive.
          print("Receiving request method...")
          local rpc_method, err = client:receive("*l")
          rpc_method = luarpc.decode("string", rpc_method)
          if err then
            local err_msg = "___ERRORPC: Receiving request method: " .. err
            print(err_msg)
            local _, err = client:send(luarpc.encode("string", err_msg) .. "\n")
            if err then
              print("___ERRONET: Sending client ___ERRORPC notification: \"" .. err_msg .. "\": " .. err)
            end
            break
          else
            print("< request method: " .. rpc_method)
          end

          -- Validate method name.
          if servant.iface.methods[rpc_method] then
            -- Parameters receive.
            local values = {}
            local i = 0
            for _, param in pairs(servant.iface.methods[rpc_method].args) do
              if param.direction == "in" or param.direction == "inout" then
                i = i + 1
                print("Receiving request method \"" .. rpc_method .. "\" value " .. i .. "...")
                if param.type ~= "void" then
                  local value, err = client:receive("*l")
                  value = luarpc.decode(param.type, value)
                  if err then
                    local err_msg = "___ERRORPC: Receiving request method \"" .. rpc_method .. "\" value " .. i .. ": " .. err
                    print(err_msg)
                    local _, err = client:send(luarpc.encode("string", err_msg) .. "\n")
                    if err then
                      print("___ERRONET: Sending client ___ERRORPC notification: \"" .. err_msg .. "\": " .. err)
                    end
                    skip = true
                    break
                  else
                    -- Validate request types after receive.
                    if not luarpc.validate_type(param.type, value) then
                      local err_msg = "___ERRORPC: Wrong request type received for value " .. i .. " \"" .. value .. "\" for method \"" .. rpc_method .. "\" expecting type \"" .. param.type .. "\""
                      print(err_msg)
                      local _, err = client:send(luarpc.encode("string", err_msg) .. "\n")
                      if err then
                        print("___ERRONET: Sending client ___ERRORPC notification: \"" .. err_msg .. "\": " .. err)
                      end
                      skip = true
                      break
                    end

                    -- Show request value.
                    print("< request value: " .. value)
                    -- Method params to be used when calling local object.
                    table.insert(values, value)
                  end
                else
                  -- Show request value.
                  print("< request value: void")
                end
              end
            end

            -- Call method on server.
            if not skip then
              -- Separate result and extra results for multisend.
              local packed_result = {pcall(servant.obj[rpc_method], unpack(values))}
              local status = packed_result[1]

              if not status then
                local err_msg = "___ERRORPC: Problem calling method \"" .. rpc_method .. "\""
                print(err_msg)
                local _, err = client:send(luarpc.encode("string", err_msg) .. "\n")
                if err then
                  print("___ERRONET: Sending client ___ERRORPC notification: \"" .. err_msg .. "\": " .. err)
                end
              else
                -- XXX Void result placeholder.
                if servant.iface.methods[rpc_method].resulttype == "void" then
                  table.insert(packed_result, 2, "")
                end

                -- Validate response types before send.
                if not luarpc.validate_type(servant.iface.methods[rpc_method].resulttype, packed_result[2]) then
                  local err_msg = "___ERRORPC: Wrong response type for value \"" .. packed_result[2] .. "\" for method \"" .. rpc_method .. "\" expecting type \"" .. servant.iface.methods[rpc_method].resulttype .. "\""
                  print(err_msg)
                  local _, err = client:send(luarpc.encode("string", err_msg) .. "\n")
                  if err then
                    print("___ERRONET: Sending client ___ERRORPC notification: \"" .. err_msg .. "\": " .. err)
                  end
                end

                -- Result.
                if servant.iface.methods[rpc_method].resulttype ~= "void" then
                  local result = packed_result[2]
                  -- Show response value.
                  print("> response result: " .. result)
                  -- Return result to client.
                  local _, err = client:send(luarpc.encode(servant.iface.methods[rpc_method].resulttype, result) .. "\n")
                  if err then
                    print("___ERRONET: Sending response method \"" .. rpc_method .. "\" with result \"" .. result .. "\": " .. err)
                  end
                else
                  -- Show response value.
                  print("> response result: void")
                end

                -- Extra results.
                local i = 2
                for _, param in pairs(servant.iface.methods[rpc_method].args) do
                  if param.direction == "out" or param.direction == "inout" then
                    if param.type ~= "void" then
                      i = i + 1

                      -- Validate extra response types before send.
                      if not luarpc.validate_type(param.type, packed_result[i]) then
                        local err_msg = "___ERRORPC: Wrong extra response type for value \"" .. packed_result[i] .. "\" for method \"" .. rpc_method .. "\" expecting type \"" .. param.type .. "\""
                        print(err_msg)
                        local _, err = client:send(luarpc.encode("string", err_msg) .. "\n")
                        if err then
                          print("___ERRONET: Sending client ___ERRORPC notification: \"" .. err_msg .. "\": " .. err)
                          break
                        end
                      end

                      -- Show extra response value.
                      print("> response extra result: " .. packed_result[i])
                      -- Return extra result to client.
                      local _, err = client:send(luarpc.encode(param.type, packed_result[i]) .. "\n")
                      if err then
                        print("___ERRONET: Sending response method \"" .. rpc_method .. "\" with extra result \"" .. packed_result[i] .. "\": " .. err)
                        break
                      end
                    end
                  end
                end
              end
            end
          else
            local err_msg = "___ERRORPC: Invalid request method \"" .. rpc_method .. "\""
            print(err_msg)
            local _, err = client:send(luarpc.encode("string", err_msg) .. "\n")
            if err then
              print("___ERRONET: Sending client ___ERRORPC notification: \"" .. err_msg .. "\": " .. err)
            end
          end

          -- Terminate connection.
          client:close()
        end
      end
    end
  end
end

function luarpc.createProxy(server_address, server_port, interface_file)
  print("Building proxy object for server " .. server_address .. " on port " .. server_port .. "...")

  -- Proxy object.
  local pobj = {}

  -- Interface.
  dofile(interface_file)

  -- Catch all not defined methods and throw an error.
  local mt = {__index = function (...)
    local arg = {...}
    return function ()
      local rpc_method = arg[2]
      print()
      print("* Params passed to proxy object when calling \"" .. rpc_method .. "\":")
      for _, v in pairs(arg) do print(v) end
      return "___ERRORPC: Invalid request method \"" .. rpc_method .. "\""
    end
  end}
  setmetatable(pobj, mt)

  -- Proxied methods builder.
  for rpc_method, method in pairs(myinterface.methods) do
    pobj[rpc_method] = function(...)
      local arg = {...}
      print()
      print("* Params passed to proxy object when calling \"" .. rpc_method .. "\":")
      for _, v in pairs(arg) do print(v) end

      -- Validate request types before send.
      local i = 0
      for _, param in pairs(myinterface.methods[rpc_method].args) do
        if param.direction == "in" or param.direction == "inout" then
          if param.type ~= "void" then
            i = i + 1
            local value = arg[i]
            if not luarpc.validate_type(param.type, value) then
              local err_msg = "___ERRORPC: Wrong request type passed for value \"" .. value .. "\" for method \"" .. rpc_method .. "\" expecting type \"" .. param.type .. "\""
              print(err_msg)
              return err_msg
            end
          end
        end
      end

      -- Validate request #params.
      if #arg ~= i then
        local err_msg = "___ERRORPC: Wrong request number of arguments for method \"" .. rpc_method .. "\" expecting " .. i .. " got " .. #arg
        print(err_msg)
        return err_msg
      end

      -- Client connection to server.
      local client, err = socket.connect(server_address, server_port)
      if err then
        local err_msg = "___ERRONET: Could not connect to " .. server_address .. " on port " .. server_port .. ": " .. err
        print(err_msg)
        return err_msg
      end

      -- Connection options.
      client:setoption("keepalive", true)
      client:setoption("linger", {on = false, timeout = 0})
      client:setoption("tcp-nodelay", true)
      client:settimeout(10) -- send/receive timeout

      -- Connection info.
      local ip, port = client:getsockname()
      print("Connected to " .. ip .. " on port " .. port)

      -- Send request method.
      print("Sending request method \"" .. rpc_method .. "\"...")
      local _, err = client:send(luarpc.encode("string", rpc_method) .. "\n")
      if err then
        local err_msg = "___ERRONET: Sending request method \"" .. rpc_method .. "\": " .. err
        print(err_msg)
        return err_msg
      end

      -- Show request method.
      print("> request method: " .. rpc_method)

      -- Send request values.
      local i = 0
      for _, param in pairs(myinterface.methods[rpc_method].args) do
        if param.direction == "in" or param.direction == "inout" then
          if param.type ~= "void" then
            i = i + 1
            local value = arg[i]
            print("Sending request method \"" .. rpc_method .. "\" value " .. i .. " \"" .. value .. "\"")
            local _, err = client:send(luarpc.encode(param.type, value) .. "\n")
            if err then
              local err_msg = "___ERRONET: Sending request method \"" .. rpc_method .. "\" value " .. i .. " \"" .. value .. "\": " .. err
              print(err_msg)
              return err_msg
            end

            -- Show request value.
            print("> request value: " .. value)
          else
            -- Show request value.
            print("Sending request method \"" .. rpc_method .. "\" value " .. i .. " \"\"")
            print("> request value: void")
          end
        end
      end

      -- Receive result.
      local values = {}
      if myinterface.methods[rpc_method].resulttype ~= "void" then
        print("Receiving response method \"" .. rpc_method .. "\" value...")
        local value, err = client:receive("*l")
        value = luarpc.decode(myinterface.methods[rpc_method].resulttype, value)
        if err then
          local err_msg = "___ERRORPC: Receiving response method \"" .. rpc_method .. "\" value: " .. err
          print(err_msg)
          return err_msg
        else
          -- Validate response types after receive.
          if not luarpc.validate_type(myinterface.methods[rpc_method].resulttype, value) then
            local err_msg = "___ERRORPC: Wrong response type received for value \"" .. value .. "\" for method \"" .. rpc_method .. "\" expecting type \"" .. myinterface.methods[rpc_method].resulttype .. "\""
            print(err_msg)
            return err_msg
          end

          -- Show response value.
          print("< response value: " .. value)
          -- Results to be returned from proxied object.
          table.insert(values, value)
        end
      else
        -- Show response value.
        print("Receiving response method \"" .. rpc_method .. "\" value...")
        print("< response value: void")
      end

      -- Receive extra results.
      local i = 0
      for _, param in pairs(myinterface.methods[rpc_method].args) do
        if param.direction == "out" or param.direction == "inout" then
          if param.type ~= "void" then
            i = i + 1
            print("Receiving response method \"" .. rpc_method .. "\" extra value " .. i .. "...")
            local value, err = client:receive("*l")
            value = luarpc.decode(param.type, value)
            if err then
              print("___ERRORPC: Receiving response method \"" .. rpc_method .. "\" extra value " .. i .. ": " .. err)
              break
            else
              -- Validate extra response types after receive.
              if not luarpc.validate_type(param.type, value) then
                print("___ERRORPC: Wrong extra response type received for extra value " .. i .. " \"" .. value .. "\" for method \"" .. rpc_method .. "\" expecting type \"" .. param.type .. "\"")
                break
              end

              -- Show response extra value.
              print("< response extra value: " .. value)
              -- Results to be returned from proxied object.
              table.insert(values, value)
            end
          else
            -- Show response value.
            print("Receiving response method \"" .. rpc_method .. "\" extra value " .. i .. "...")
            print("< response extra value: void")
          end
        end
      end

      -- Terminate connection.
      client:close()

      -- Return unpacked result.
      return unpack(values)
    end
  end

  return pobj
end

return luarpc
