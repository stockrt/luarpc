#!/bin/bash

sudo iptables -F
sudo iptables -X
sudo iptables -Z
sudo iptables -N INET_IN
sudo iptables -N INET_OUT
sudo iptables -A INPUT -j INET_IN
sudo iptables -A OUTPUT -j INET_OUT
sudo iptables -A INET_IN -p tcp -d localhost --dport 5001
sudo iptables -A INET_OUT -p tcp -d localhost --sport 5001
sudo iptables -A INET_IN -p tcp -d localhost --dport 5002
sudo iptables -A INET_OUT -p tcp -d localhost --sport 5002
