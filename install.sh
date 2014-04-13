#!/bin/bash

# MacOS
brew install lua
brew install luarocks
luarocks install luasocket
luarocks install busted

# Ubuntu
sudo apt-get install lua5.1
sudo apt-get install luarocks
sudo luarocks install luasocket
sudo luarocks install busted

# Source
export LUA_PREFIX="/tmp/lua"
mkdir -p $LUA_PREFIX

cd $LUA_PREFIX
wget http://www.lua.org/ftp/lua-5.2.3.tar.gz
tar xzvf lua-5.2.3.tar.gz
cd lua-5.2.3
make linux

cd $LUA_PREFIX
wget https://github.com/diegonehab/luasocket/archive/v3.0-rc1.tar.gz
tar xzvf v3.0-rc1.tar.gz
cd luasocket-3.0-rc1
cp -a $LUA_PREFIX/lua-5.2.3/src/* src/
make

cd src
mkdir socket mime
cp -a mime.so.1.0.3 mime/core.so
cp -a socket.so.3.0-rc1 socket/core.so

echo "socket = require('socket')"
./lua
