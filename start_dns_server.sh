#!/bin/bash

# Step 1: Identify and kill the process using port 5300
pid=$(lsof -i :5300 -t)
if [ -n "$pid" ]; then
  echo "Killing process with PID $pid"
  kill $pid
else
  echo "No process found using port 5300"
fi

# Step 2: Move to dnstt-server directory and get new nameserver input
cd /root/dnstt/dnstt-server
read -p "Enter the new nameserver: " new_nameserver

# Step 3: Start dnstt-server using screen
screen -dmS slowdns ./dnstt-server -udp :5300 -privkey-file server.key $new_nameserver 127.0.0.1:22

echo "dnstt-server started with new nameserver: $new_nameserver"
