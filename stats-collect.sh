#!/bin/bash

sudo iptables -L -vxn | grep pt:500
