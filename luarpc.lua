-- http://www.inf.puc-rio.br/~noemi/sd-14/trab1.html

--[[
TODO:
### Ainda vou refinar:
- Revisar protocolo (número de parâmetros e de retornos);
OK mas ainda tem erro com slahes - Utilizar encode/decode para multiline e outros escapes combinados com a turma;
- Do ponto de vista de engenharia, algumas chamadas poderiam ser encapsuladas para termos menos linhas de código e menos repetição;
- Testado apenas contra LUA 5.1:
Lua 5.1.5  Copyright (C) 1994-2012 Lua.org, PUC-Rio

- Apenas do in ou dos inout tb?
O protocolo é baseado na troca de strings ascii. Cada chamada é realizada pelo nome do método seguido da lista de parâmetros in. Entre o nome do método e o primeiro argumento, assim como depois de cada argumento, deve vir um fim de linha. A resposta deve conter o valor resultante seguido dos valores dos argumentos de saída, cada um em uma linha. Caso ocorra algum erro na execução da chamada, o servidor deve responder com uma string iniciada com "___ERRORPC: ", possivelmente seguida de uma descrição mais específica do erro (por exemplo, "função inexistente").

TODO:
local r, s = p1.foo(3, 5)
Como sugerido nesse exemplo, um parâmetro out deve ser tratado como um
resultado a mais da função.
Um parâmetro inout é mapeado em um argumento de entrada e um resultado a mais.
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

function unescape (s)
  s = string.gsub(s, "+", " ")
  s = string.gsub(s, "%%(%x%x)", function (h)
    return string.char(tonumber(h, 16))
  end)
  return s
end

function decode (s)
  for name, value in string.gfind(s, "([^&=]+)=([^&=]+)") do
    name = unescape(name)
    value = unescape(value)
    cgi[name] = value
  end
end

function escape (s)
  s = string.gsub(s, "([&=+%c])", function (c)
    return string.format("%%%02X", string.byte(c))
  end)
  s = string.gsub(s, " ", "+")
  return s
end

function encode (t)
  local s = ""
  for k,v in pairs(t) do
    s = s .. "&" .. escape(k) .. "=" .. escape(v)
  end
  return string.sub(s, 2)     -- remove first `&'
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
    return tonumber(value)
  else
    return value
  end
end

function luarpc.createServant(obj, interface_file)
  print("Setting up servant " .. #servant_list + 1 .. "...")

  -- tcp, bind, listen shortcut.
  local server, err = socket.bind("*", 0, 2048)
  if err then
    local err_msg = "___ERRONET: Server could not bind: " .. err
    print(err_msg)
    return err_msg
  end

  -- Step by step.
  -- local server = socket.tcp()
  -- server:bind("*", 0)
  -- server:listen(2048)

  -- Connection options.
  server:setoption('keepalive', true)
  server:setoption('linger', {on = false, timeout = 0})
  server:setoption('tcp-nodelay', true)
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
          if err then
            local err_msg = "___ERRORPC: Receiving request method: " .. err
            print(err_msg)
            local _, err = client:send(err_msg .. "\n")
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
            local params = servant.iface.methods[rpc_method].args
            local i = 0
            for _, param in pairs(params) do
              if param.direction == "in" or param.direction == "inout" then
                i = i + 1
                print("Receiving request method \"" .. rpc_method .. "\" value " .. i .. "...")
                if param.type ~= "void" then
                  local value, err = client:receive("*l")
                  if err then
                    local err_msg = "___ERRORPC: Receiving request method \"" .. rpc_method .. "\" value " .. i .. ": " .. err
                    print(err_msg)
                    local _, err = client:send(err_msg .. "\n")
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
                      local _, err = client:send(err_msg .. "\n")
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
              -- One result fits all.
              local status, result = pcall(servant.obj[rpc_method], unpack(values))

              -- Separate results for multisend.
              --[[
              local packed_result = {pcall(servant.obj[rpc_method], unpack(values))}
              local status = packed_result[1]
              ]]

              if not status then
                local err_msg = "___ERRORPC: Problem calling method \"" .. rpc_method .. "\""
                print(err_msg)
                local _, err = client:send(err_msg .. "\n")
                if err then
                  print("___ERRONET: Sending client ___ERRORPC notification: \"" .. err_msg .. "\": " .. err)
                end
              else
                -- Validate response types before send?

                -- One result fits all.
                print("> response result: " .. result)
                -- Return result to client.
                local _, err = client:send(result .. "\n")
                if err then
                  print("___ERRONET: Sending response method \"" .. rpc_method .. "\" with result \"" .. result .. "\": " .. err)
                end

                -- Separate results for multisend.
                --[[
                for _, result in pairs({unpack(packed_result, 2)}) do
                  print("= response result: " .. result)
                  -- Return result to client.
                  local _, err = client:send(result .. "\n")
                  if err then
                    print("___ERRONET: Sending response method \"" .. rpc_method .. "\" with result \"" .. result .. "\": " .. err)
                  end
                end
                ]]
              end
            end
          else
            local err_msg = "___ERRORPC: Invalid request method \"" .. rpc_method .. "\""
            print(err_msg)
            local _, err = client:send(err_msg .. "\n")
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

  for rpc_method, method in pairs(myinterface.methods) do
    -- Proxied methods builder.
    pobj[rpc_method] = function(...)
      print()
      print("* Params passed to proxy object when calling \"" .. rpc_method .. "\":")
      table.foreach(arg, print)

      -- Method in/out params.
      local params = myinterface.methods[rpc_method].args

      -- Validate request types before send.
      local i = 0
      for _, param in pairs(params) do
        if param.direction == "in" or param.direction == "inout" then
          if param.type ~= "void" then
            i = i + 1
            local value = arg[i]
            if not luarpc.validate_type(value, param.type) then
              local err_msg = "___ERRORPC: Wrong request type passed for value \"" .. value .. "\" for method \"" .. rpc_method .. "\" expecting type \"" .. param.type .. "\""
              print(err_msg)
              return err_msg
            end
          end
        end
      end

      -- Validate request #params.
      if arg.n ~= i then
        local err_msg = "___ERRORPC: Wrong request number of arguments for method \"" .. rpc_method .. "\" expecting " .. i .. " got " .. arg.n
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
      client:setoption('keepalive', true)
      client:setoption('linger', {on = false, timeout = 0})
      client:setoption('tcp-nodelay', true)
      client:settimeout(10) -- send/receive timeout

      -- Connection info.
      local ip, port = client:getsockname()
      print("Connected to " .. ip .. " on port " .. port)

      -- Send request method.
      print("Sending request method \"" .. rpc_method .. "\"...")
      local _, err = client:send(rpc_method .. "\n")
      if err then
        local err_msg = "___ERRONET: Sending request method \"" .. rpc_method .. "\": " .. err
        print(err_msg)
        return err_msg
      end

      -- Show request method.
      print("> request method: " .. rpc_method)

      -- Send request values.
      local i = 0
      for _, param in pairs(params) do
        if param.direction == "in" or param.direction == "inout" then
          if param.type ~= "void" then
            i = i + 1
            local value = arg[i]
            print("Sending request method \"" .. rpc_method .. "\" value " .. i .. " \"" .. value .. "\"")
            local _, err = client:send(value .. "\n")
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

      -- Receive response.
      local i = 0
      local values = {}
      for _, param in pairs(params) do
        if param.direction == "out" or param.direction == "inout" then
          if param.type ~= "void" then
            i = i + 1
            print("Receiving response method \"" .. rpc_method .. "\" value " .. i .. "...")
            local value, err = client:receive("*l")
            if err then
              print("___ERRORPC: Receiving response method \"" .. rpc_method .. "\" value " .. i .. ": " .. err)
              break
            else
              -- Validate response types after receive.
              if not luarpc.validate_type(value, param.type) then
                print("___ERRORPC: Wrong response type received for value " .. i .. " \"" .. value .. "\" for method \"" .. rpc_method .. "\" expecting type \"" .. param.type .. "\"")
                break
              end

              -- Show response value.
              print("< response value: " .. value)
              -- Results to be returned from proxied object.
              table.insert(values, value)
            end
          else
            -- Show response value.
            print("Receiving response method \"" .. rpc_method .. "\" value " .. i .. "...")
            print("< response value: void")
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
