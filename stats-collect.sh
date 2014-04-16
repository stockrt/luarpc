#!/bin/bash

sudo iptables -L -v -n | grep pt:500
