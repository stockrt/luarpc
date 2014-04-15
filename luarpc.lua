-- http://www.inf.puc-rio.br/~noemi/sd-14/trab1.html

local socket = require("socket")
local unpack = unpack or table.unpack

-- This is the main module luarpc.
local luarpc = {}

-- Lists.
local servant_list = {} -- {server, obj, iface, client_list}
local pclient_list = {} -- {server_address .. server_port = client}

-- Global namespace.
myinterface = {}

function interface(iface)
  -- Global namespace.
  myinterface = iface
end

function luarpc.default_value_by_type(param_type)
  if param_type == "char" then
    return "R"
  elseif param_type == "string" then
    return "PUC-Rio"
  elseif param_type == "double" then
    return 3.1415
  elseif param_type == "void" then
    return nil
  else
    return nil
  end
end

function luarpc.validate_type(param_type, value)
  if param_type == "char" then
    if #tostring(value) == 1 then
      return true
    end
  elseif param_type == "string" then
    if type(value) == "string" then
      return true
    end
  elseif param_type == "double" then
    if tonumber(value) then
      return true
    end
  elseif param_type == "void" then
    if value == nil then
      return true
    end
  end

  return false
end

function luarpc.encode(param_type, value)
  if param_type == "string" then
    local x = "XXXXXXXXXX"
    local str = value:gsub("\n", x)
    str = str:gsub("\\", "\\\\")
    str = str:gsub("\"", "\\\"")
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
    str = str:gsub("\\\"", "\"")
    str = str:gsub(x, "\n")
    return str
  elseif param_type == "double" then
    if tonumber(value) then
      return tonumber(value)
    end
  elseif param_type == "void" then
    return nil
  end

  return value
end

function luarpc.serialize(param_type, value)
  if param_type == "string" then
    value = "\"" .. luarpc.encode(param_type, value) .. "\""
  elseif param_type == "void" then
    value = "\"" .. luarpc.encode(param_type, value) .. "\""
  end

  return value
end

function luarpc.deserialize(param_type, value)
  if param_type == "string" then
    value = luarpc.decode(param_type, value):sub(2, -2)
  elseif param_type == "void" then
    value = luarpc.decode(param_type, value)
  end

  return value
end

function luarpc.send_msg(params)
  local status = true
  local ret_msg = "OK"
  local msg = params.msg

  -- Info.
  print(params.err_msg)

  -- Validate type before send.
  if not luarpc.validate_type(params.param_type, msg) then
    ret_msg = "___ERRORPC: Wrong type for msg \"" .. tostring(msg) .. "\" expecting type \"" .. tostring(params.param_type) .. "\""
    print(ret_msg)

    local _, err = params.client:send(luarpc.serialize("string", ret_msg) .. "\n")
    if err then
      ret_msg = "___ERRONET: Sending client ___ERRORPC notification: \"" .. tostring(err_msg) .. "\" - " .. tostring(err)
      print(ret_msg)

      -- Discard disconnected peer.
      if err == "closed" then
        luarpc.discard_client(params.client, params.client_list)
      end
    end

    status = false
  else
    -- Serialize / Encode.
    if params.serialize then
      msg = luarpc.serialize(params.param_type, msg)
    else
      msg = luarpc.encode(params.param_type, msg)
    end

    -- Send.
    local _, err = params.client:send(msg .. "\n")
    if err then
      ret_msg = "___ERRONET: " .. tostring(params.err_msg)
      print(ret_msg)

      -- Discard disconnected peer.
      if err == "closed" then
        luarpc.discard_client(params.client, params.client_list)
      end

      status = false
    end
  end

  return status, ret_msg
end

function luarpc.recv_msg(params)
  local status = true

  -- Info.
  print(params.err_msg)

  -- Receive.
  local ret_msg, err = params.client:receive("*l")
  if err then
    ret_msg = "___ERRONET: " .. tostring(params.err_msg) .. " - " .. tostring(err)
    print(ret_msg)

    -- Discard disconnected peer.
    if err == "closed" then
      luarpc.discard_client(params.client, params.client_list)
    end

    status = false
  else
    -- Deserialize / Decode.
    if params.deserialize then
      ret_msg = luarpc.deserialize(params.param_type, ret_msg)
    else
      ret_msg = luarpc.decode(params.param_type, ret_msg)
    end

    -- Validate type after received.
    if not luarpc.validate_type(params.param_type, ret_msg) then
      ret_msg = "___ERRORPC: Wrong type for msg \"" .. tostring(ret_msg) .. "\" expecting type \"" .. tostring(params.param_type) .. "\""
      print(ret_msg)

      luarpc.send_msg{msg=ret_msg, client=params.client, client_list=params.client_list, param_type="string", serialize=true, err_msg="Sending client ___ERRORPC notification"}

      status = false
    end
  end

  return status, ret_msg
end

function luarpc.discard_client(client, client_list)
  -- Peer may have closed the connection.
  print("Discarding connection closed by peer.")
  client:close()

  if client_list then
    -- Current client list.
    if #client_list == 0 then
      print("- Current client count: 0")
    else
      for k, _ in pairs(client_list) do print("- Current client count: " .. k) end
    end

    -- Find and remove closed client.
    for k, v in pairs(client_list) do
      if client == v then
        table.remove(client_list, k)
      end
    end

    -- New client list.
    if #client_list == 0 then
      print("+ New client count: 0")
    else
      for k, _ in pairs(client_list) do print("+ New client count: " .. k) end
    end
  end
end

function luarpc.createServant(obj, interface_file, server_port, pool_size)
  print("Setting up servant " .. #servant_list + 1 .. "...")

  -- Dynamic or static port.
  local s_port = 0
  if server_port then
    s_port = server_port
  end

  -- Default pool size.
  local p_size = 3
  if pool_size then
    p_size = pool_size
  end

  -- tcp, bind, listen shortcut.
  local server, err = socket.bind("*", s_port, 2048)
  if err then
    local err_msg = "___ERRONET: Server could not bind to *:" .. s_port .. " - " .. tostring(err)
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
  server:settimeout(0) -- accept/send/receive timeout

  -- Interface.
  dofile(interface_file)

  -- Servant.
  local servant = {
    server = server,
    obj = obj,
    iface = myinterface,
    client_list = {},
    pool_size = p_size,
  }

  -- Servant list.
  table.insert(servant_list, servant)

  -- Connection info.
  local l_ip, l_port = server:getsockname()
  local port_file = "port" .. #servant_list .. ".txt"
  local file = io.open(port_file, "w")
  file:write(l_port .. "\n")
  file:close()
  print("Please connect to " .. tostring(l_ip) .. ":" .. tostring(l_port) .. " (also, you can script clients reading port number from file " .. port_file .. ")")
  print("Pool size: " .. p_size)
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
      local server_accept_ready_list, _, err = socket.select({servant.server}, nil, 0)
      for _, server in pairs(server_accept_ready_list) do
        if type(server) ~= "number" then
          local client = server:accept()

          -- Client connected.
          if client then
            -- Connection options.
            client:setoption("keepalive", true)
            client:setoption("linger", {on = false, timeout = 0})
            client:setoption("tcp-nodelay", true)
            client:settimeout(10) -- send/receive timeout (line inactivity).

            -- Client list.
            table.insert(servant.client_list, client)

            -- Connection info.
            local l_ip, l_port = client:getsockname()
            local r_ip, r_port = client:getpeername()
            print("Client " .. tostring(r_ip) .. ":" .. tostring(r_port) .. " connected on " .. tostring(l_ip) .. ":" .. tostring(l_port))

            -- Only manage connection pool if pool_size if configured for more than
            -- 0 clients.
            if servant.pool_size > 0 then
              -- Pool size limit.
              print("- Current number of connected clients: " .. #servant.client_list .. "/" .. servant.pool_size)
              if #servant.client_list > servant.pool_size then
                print("Pool size of " .. servant.pool_size .. " connections exceeded, discarding old clients.")
                while #servant.client_list > servant.pool_size do
                  old_client = table.remove(servant.client_list, 1)
                  local l_ip, l_port = old_client:getsockname()
                  local r_ip, r_port = old_client:getpeername()
                  print("Closing old client connection " .. tostring(r_ip) .. ":" .. tostring(r_port) .. " on " .. tostring(l_ip) .. ":" .. tostring(l_port))
                  old_client:close()
                end
                print("+ New number of connected clients: " .. #servant.client_list .. "/" .. servant.pool_size)
              end
            end
          end
        end
      end

      -- Connected client sent some data for this servant.
      local client_recv_ready_list, _, err = socket.select(servant.client_list, nil, 0)
      for _, client in pairs(client_recv_ready_list) do
        skip = false

        if type(client) ~= "number" then
          -- Connection info.
          local l_ip, l_port = client:getsockname()
          local r_ip, r_port = client:getpeername()
          print("Receiving request data from client " .. tostring(r_ip) .. ":" .. tostring(r_port) .. " on " .. tostring(l_ip) .. ":" .. tostring(l_port))

          -- Method receive.
          local status, rpc_method = luarpc.recv_msg{client=client, client_list=servant.client_list, param_type="string", deserialize=false, err_msg="Receiving request method"}
          if not status then
            -- Interrupt recv ready clients loop.
            break
          end
          print("< request method: " .. tostring(rpc_method))

          -- Validate method name.
          if servant.iface.methods[rpc_method] then
            -- Parameters receive.
            local values = {}
            local i = 0
            for _, param in pairs(servant.iface.methods[rpc_method].args) do
              if param.direction == "in" or param.direction == "inout" then
                i = i + 1
                local status, value = luarpc.recv_msg{client=client, client_list=servant.client_list, param_type=param.type, deserialize=true, err_msg="Receiving request method \"" .. tostring(rpc_method) .. "\" value #" .. i}
                if not status then
                  -- Do not call method since we have failed to receive the msg.
                  skip = true
                  -- Interrupt param recv loop.
                  break
                end

                -- Show request value.
                print("< request value: " .. tostring(value))
                -- Method params to be used when calling local object.
                table.insert(values, value)
              end
            end

            -- Call method on server.
            if not skip then
              -- Separate result and extra results for multisend.
              local packed_result = {pcall(servant.obj[rpc_method], unpack(values))}
              local exec_status = packed_result[1]
              for _, v in pairs(packed_result) do print("- Packed result: " .. tostring(v)) end

              -- Void result placeholder.
              if servant.iface.methods[rpc_method].resulttype == "void" then
                packed_result[1] = nil
              else
                table.remove(packed_result, 1)
              end
              for _, v in pairs(packed_result) do print("+ Packed result: " .. tostring(v)) end

              -- Validate response #params.
              local i = 1
              for _, param in pairs(servant.iface.methods[rpc_method].args) do
                if param.direction == "out" or param.direction == "inout" then
                  i = i + 1
                end
              end
              if #packed_result ~= i then
                local err_msg = "___ERRORPC: Wrong response number of arguments for method \"" .. tostring(rpc_method) .. "\" expecting " .. i .. " got " .. #packed_result
                print(err_msg)

                -- Try to fix things with defaults values for each missing param,
                -- according to it's type.
                print("Trying to fix things for method \"" .. rpc_method .. "\" returning default values for missing responses.")
                local j = 1
                for _, param in pairs(servant.iface.methods[rpc_method].args) do
                  if param.direction == "out" or param.direction == "inout" then
                    j = j + 1
                    if not packed_result[j] then
                      packed_result[j] = luarpc.default_value_by_type(param.type)
                    end
                  end
                end

                -- Another option is to fail and don't try to fix server's output, just give up.
                -- break
              end
              for _, v in pairs(packed_result) do print("= Packed result: " .. tostring(v)) end

              if not exec_status then
                luarpc.send_msg{msg="___ERRORPC: Problem calling method \"" .. tostring(rpc_method) .. "\"", client=client, client_list=servant.client_list, param_type="string", serialize=true, err_msg="Sending client ___ERRORPC notification"}
              else
                -- Result.
                local status, msg = luarpc.send_msg{msg=packed_result[1], client=client, client_list=servant.client_list, param_type=servant.iface.methods[rpc_method].resulttype, serialize=true, err_msg="Sending response method \"" .. tostring(rpc_method) .. "\" with result \"" .. tostring(packed_result[1]) .. "\""}
                if status then
                  -- Show response value.
                  print("> response result: " .. tostring(packed_result[1]))

                  -- Extra results.
                  local i = 1
                  for _, param in pairs(servant.iface.methods[rpc_method].args) do
                    if param.direction == "out" or param.direction == "inout" then
                      i = i + 1
                      local status, msg = luarpc.send_msg{msg=packed_result[i], client=client, client_list=servant.client_list, param_type=param.type, serialize=true, err_msg="Sending extra response method \"" .. tostring(rpc_method) .. "\" with result \"" .. tostring(packed_result[i]) .. "\""}
                      if status then
                        -- Show extra response value.
                        print("> response extra result: " .. tostring(packed_result[i]))
                      else
                        print(msg)
                        -- Interrupt param extra result send loop.
                        break
                      end
                    end
                  end
                else
                  -- Err.
                  print(msg)
                end
              end
            end
          else
            luarpc.send_msg{msg="___ERRORPC: Invalid request method \"" .. tostring(rpc_method) .. "\"", client=client, client_list=servant.client_list, param_type="string", serialize=true, err_msg="Sending client ___ERRORPC notification"}
          end

          -- Close connection after serving if pool_size is configured for 0 or
          -- less clients.
          if servant.pool_size <= 0 then
            local l_ip, l_port = client:getsockname()
            local r_ip, r_port = client:getpeername()
            print("No connection pool configured, closing current client connection " .. tostring(r_ip) .. ":" .. tostring(r_port) .. " on " .. tostring(l_ip) .. ":" .. tostring(l_port))
            luarpc.discard_client(client, servant.client_list)
          end
        end
      end
    end
  end
end

function luarpc.createProxy(server_address, server_port, interface_file)
  print("Building proxy object for server " .. server_address .. ":" .. server_port .. "...")

  -- Proxy object.
  local pobj = {}

  -- Interface.
  dofile(interface_file)

  -- Catch all not defined methods and throw an error.
  local catch_undef_method = {__index = function (...)
    local arg = {...}
    return function ()
      local rpc_method = arg[2]
      local err_msg = "___ERRORPC: Invalid request method \"" .. tostring(rpc_method) .. "\""
      print(err_msg)
      return err_msg
    end
  end}
  setmetatable(pobj, catch_undef_method)

  -- Proxied methods builder.
  for rpc_method, method in pairs(myinterface.methods) do
    pobj[rpc_method] = function (...)
      local arg = {...}
      print()
      print("* Params passed to proxy object when calling \"" .. tostring(rpc_method) .. "\":")
      for _, v in pairs(arg) do print("- " .. tostring(v)) end

      -- Validate request #params.
      local i = 0
      for _, param in pairs(myinterface.methods[rpc_method].args) do
        if param.direction == "in" or param.direction == "inout" then
          if param.type ~= "void" then i = i + 1 end
        end
      end
      if #arg ~= i then
        local err_msg = "___ERRORPC: Wrong request number of arguments for method \"" .. tostring(rpc_method) .. "\" expecting " .. i .. " got " .. #arg
        print(err_msg)

        -- Try to fix things with defaults values for each missing param,
        -- according to it's type.
        print("Trying to fix things for method \"" .. rpc_method .. "\" passing default values for missing parameters.")
        local j = 0
        for _, param in pairs(myinterface.methods[rpc_method].args) do
          if param.direction == "in" or param.direction == "inout" then
            j = j + 1
            if not arg[j] then
              arg[j] = luarpc.default_value_by_type(param.type)
            end
          end
        end

        -- Another option is to fail and don't try to fix user's input, just give up.
        -- return err_msg
      end

      -- Test client connection to server.
      local client = pclient_list[server_address .. server_port]
      if client then
        -- Non-blocking connection closed test.
        client:settimeout(0)
        local _, err = client:receive(0)
        client:settimeout(10)
        if err == "closed" then
          -- Close and remove client connection.
          client:close()
          pclient_list[server_address .. server_port] = nil
          print("Cached connection was closed by server " .. tostring(server_address) .. ":" .. tostring(server_port))
        else
          print("Cached connection seems ok for server " .. tostring(server_address) .. ":" .. tostring(server_port))
        end
      else
        print("No cached connection found for server " .. tostring(server_address) .. ":" .. tostring(server_port))
      end

      -- Try and cache connection to server.
      if not pclient_list[server_address .. server_port] then
        -- Estabilish client connection to server.
        print("Trying to estabilish and cache connection for server " .. tostring(server_address) .. ":" .. tostring(server_port))
        local client, err = socket.connect(server_address, server_port)
        if err then
          local err_msg = "___ERRONET: Could not connect to " .. tostring(server_address) .. ":" .. tostring(server_port) .. " - " .. tostring(err)
          print(err_msg)
          return err_msg
        else
          -- Connection options.
          client:setoption("keepalive", true)
          client:setoption("linger", {on = false, timeout = 0})
          client:setoption("tcp-nodelay", true)
          client:settimeout(10) -- send/receive timeout

          print("Caching connection for server " .. tostring(server_address) .. ":" .. tostring(server_port))
          pclient_list[server_address .. server_port] = client
        end
      end

      -- Use cached connection to server.
      local client = pclient_list[server_address .. server_port]
      if not client then
        local err_msg = "___ERRONET: Could not retrieve cached connection to " .. tostring(server_address) .. ":" .. tostring(server_port)
        print(err_msg)
        return err_msg
      else
        print("Found cached connection for server " .. tostring(server_address) .. ":" .. tostring(server_port) .. ", reusing it.")
      end

      -- Connection info.
      local l_ip, l_port = client:getsockname()
      local r_ip, r_port = client:getpeername()
      print("Connected to " .. tostring(r_ip) .. ":" .. tostring(r_port) .. " via " .. tostring(l_ip) .. ":" .. tostring(l_port))
      print("Sending request data to server " .. tostring(r_ip) .. ":" .. tostring(r_port) .. " via " .. tostring(l_ip) .. ":" .. tostring(l_port))

      -- Send request method.
      local status, msg = luarpc.send_msg{msg=rpc_method, client=client, param_type="string", serialize=false, err_msg="Sending request method \"" .. tostring(rpc_method) .. "\""}
      if not status then
        print(msg)
        return msg
      end

      -- Show request method.
      print("> request method: " .. tostring(rpc_method))

      -- Send request values.
      local i = 0
      for _, param in pairs(myinterface.methods[rpc_method].args) do
        if param.direction == "in" or param.direction == "inout" then
          i = i + 1
          local value = arg[i]
          local status, msg = luarpc.send_msg{msg=value, client=client, param_type=param.type, serialize=true, err_msg="Sending request method \"" .. tostring(rpc_method) .. "\" value #" .. i .. " \"" .. tostring(value) .. "\""}
          if not status then
            print(msg)
            -- Interrupt param send loop.
            return msg
          end

          -- Show request value.
          print("> request value: " .. tostring(value))
        end
      end

      -- Receive result.
      local values = {}
      local status, value = luarpc.recv_msg{client=client, param_type=myinterface.methods[rpc_method].resulttype, deserialize=true, err_msg="Receiving response method \"" .. tostring(rpc_method) .. "\" value"}

      if status then
        -- Show response value.
        print("< response value: " .. tostring(value))
        -- Results to be returned from proxied object.
        table.insert(values, value)

        -- Receive extra results.
        local i = 0
        for _, param in pairs(myinterface.methods[rpc_method].args) do
          if param.direction == "out" or param.direction == "inout" then
            i = i + 1
            local status, value = luarpc.recv_msg{client=client, param_type=param.type, deserialize=true, err_msg="Receiving response method \"" .. tostring(rpc_method) .. "\" extra value #" .. i}
            if not status then
              -- Interrupt param extra result recv loop.
              break
            end

            -- Show response extra value.
            print("< response extra value: " .. tostring(value))
            -- Results to be returned from proxied object.
            table.insert(values, value)
          end
        end
      else
        -- Err.
        print(value)
      end

      -- Return unpacked result.
      return unpack(values)
    end
  end

  return pobj
end

return luarpc
