#!/bin/bash

# Install necessary packages
sudo apt update
sudo apt install nano
sudo apt install git
sudo apt install -y golang-go

# Clone the repository and build the server
cd /root
git clone https://www.bamsoftware.com/git/dnstt.git
cd dnstt/dnstt-server
go build

# Generate key pair
./dnstt-server -gen-key -privkey-file server.key -pubkey-file server.pub

# Display the contents of server.pub and prompt the user to copy it
cat server.pub
echo "Copy the content above and press Enter when done"
read

# Edit sshd_config
sudo nano /etc/ssh/sshd_config
echo "Make sure to add 'AllowTcpForwarding yes' in the config. Press Enter when done"
read

# Restart SSH service
sudo /etc/init.d/ssh restart

# Prompt user for SSH or SSL mode
echo "Select mode: 1) SSH 2) SSL"
read mode

# Prompt user for NS domain
echo "Enter NS domain:"
read ns_domain

# Configure and start dnstt-server based on the mode
if [ "$mode" -eq 1 ]; then
    screen -dmS slowdns ./dnstt-server -udp :5300 -privkey-file server.key "$ns_domain" 127.0.0.1:22
else
    screen -dmS slowdns ./dnstt-server -udp :5300 -privkey-file server.key "$ns_domain" 127.0.0.1:443
fi

# Configure iptables rules
sudo iptables -I INPUT -p udp --dport 5300 -j ACCEPT
sudo iptables -t nat -I PREROUTING -i eth0 -p udp --dport 53 -j REDIRECT --to-ports 5300
sudo ip6tables -I INPUT -p udp --dport 5300 -j ACCEPT
sudo ip6tables -t nat -I PREROUTING -i eth0 -p udp --dport 53 -j REDIRECT --to-ports 5300

echo "Installation and configuration completed!"
