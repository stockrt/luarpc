# luarpc - RPC library in Lua


## Using in interactive shell

### Server

```shell
./rpc_server.lua interface.lua 8080 8081
```

### Client

```lua
lua

luarpc = require("luarpc")

server_address = "localhost"
server_port1 = 8080
server_port2 = 8081
interface_file = "interface.lua"

proxy1 = luarpc.createProxy(server_address, server_port1, interface_file)
proxy2 = luarpc.createProxy(server_address, server_port2, interface_file)

= proxy1.foo(1, 1)
= proxy1.boo(1)
```


## Using in the command line

### Server

```shell
./rpc_server.lua interface.lua 8080 8081
```

### Client

```shell
./rpc_client_ok.lua interface.lua localhost 8080 8081
```


## Using during benchmark

For performance tests you should use the less verbose mode of server and client.

Change **verbose to false in luarpc.lua** or run the suggested commands bellow.

Redirecting console output to /dev/null has almost the same effect in throughput as changing the flag to false.

Prefer changing the flag to false.

### Silent Server (verbose = false)

```shell
./rpc_server.lua interface.lua 8080 8081
```

### Silent Client (verbose = false)

```shell
./rpc_client_loop_boo.lua interface.lua localhost 8080 50000
```

### Silent Server (console redirection to /dev/null)

```shell
./rpc_server.lua interface.lua 8080 8081 >/dev/null 2>&1
```

### Silent Client (console output filtering)

```shell
./rpc_client_loop_boo.lua interface.lua localhost 8080 50000 | grep took
```
