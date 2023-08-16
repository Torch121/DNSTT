#!/bin/bash

# Update and install necessary packages
sudo apt update
sudo apt install git nano golang-go -y

# Clone the repository and build dnstt-server
cd /root
git clone http://www.bamsoftware.com/git/dnstt.git
cd dnstt/dnstt-server
go build

# Generate server key pair and show the content of "server.pub"
./dnstt-server -gen-key -privkey-file server.key -pubkey-file server.pub
cat server.pub
read -p "Copy the content above and press Enter after you've copied it."

# Edit the sshd_config file
nano /etc/ssh/sshd_config
read -p "Make the manual edit in the file, then press Enter after you've saved it."

# Restart SSH service
/etc/init.d/ssh restart

# Ask user to select mode
echo "Select a mode:"
echo "1. SSH"
echo "2. SSL"
read -p "Enter 1 or 2: " mode

# Ask user for NS domain
read -p "Enter the NS (Nameserver) domain: " ns_domain

if [ $mode -eq 1 ]; then
    # SSH mode
    cd /root/dnstt/dnstt-server
    screen -dmS slowdns ./dnstt-server -udp :5300 -privkey-file server.key $ns_domain 127.0.0.1:22
elif [ $mode -eq 2 ]; then
    # SSL mode
    screen -dmS slowdns ./dnstt-server -udp :5300 -privkey-file server.key $ns_domain 127.0.0.1:443
fi

# Set up iptables rules
sudo iptables -I INPUT -p udp --dport 5300 -j ACCEPT
sudo iptables -t nat -I PREROUTING -i eth0 -p udp --dport 53 -j REDIRECT --to-ports 5300
sudo ip6tables -I INPUT -p udp --dport 5300 -j ACCEPT
sudo ip6tables -t nat -I PREROUTING -i eth0 -p udp --dport 53 -j REDIRECT --to-ports 5300

echo "Script completed successfully!"
