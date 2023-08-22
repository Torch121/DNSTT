#!/bin/bash

# Function to install dnstt script
install_dnstt() {
    #!/bin/bash

# logo
echo -e "
${YELLOW}
        _        _         
       | |      | |        
   ___ | |_ ___ | | _____  
  / _ \| __/ _ \| |/ / _ \ 
 | (_) | || (_) |   < (_) |
  \___/ \__\___/|_|\_\___/" 

# Define ANSI color codes
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Install necessary packages
sudo apt update
sudo apt install -y git golang-go

# Clone the repository and build the server
cd /root
git clone https://www.bamsoftware.com/git/dnstt.git
cd dnstt/dnstt-server
go build

# Generate key pair
./dnstt-server -gen-key -privkey-file server.key -pubkey-file server.pub

# Display the contents of server.pub and prompt the user to copy it
cat server.pub
echo -e "${YELLOW}Copy the pubkey above and press Enter when done${NC}"
read

# Prompt the user to set AllowTcpForwarding yes
echo -e "${YELLOW}In the next step, look for AllowTcpForwarding and set it to 'yes' or uncomment it${NC}"
read -p "Press Enter when you're ready to continue..."

# Edit sshd_config
sudo nano /etc/ssh/sshd_config

# Ask for confirmation
echo -e "${YELLOW}Did you set 'AllowTcpForwarding yes' in the config? (y/n): ${NC}"
read confirmation
if [ "$confirmation" != "y" ]; then
    echo -e "${YELLOW}Please make sure to set 'AllowTcpForwarding yes' in the config.${NC}"
    exit 1
fi

# Restart SSH service
sudo /etc/init.d/ssh restart

# Prompt user for SSH or SSL mode
while true; do
    echo -e "${YELLOW}Select mode: 1: SSH 2: SSL${NC}"
    read mode

    if [ "$mode" == "1" ] || [ "$mode" == "2" ]; then
        break
    else
        echo -e "${YELLOW}Please enter either 1 or 2.${NC}"
    fi
done

# Prompt user for NS domain
echo -e "${YELLOW}Enter your NS domain:${NC}"
read ns_domain

# Add your command here (e.g., cd /root/dnstt/dnstt-server)
cd /root/dnstt/dnstt-server

# Configure and start dnstt-server based on the mode
if [ "$mode" == "1" ]; then
    screen -dmS slowdns ./dnstt-server -udp :5300 -privkey-file server.key "$ns_domain" 127.0.0.1:22
else
    screen -dmS slowdns ./dnstt-server -udp :5300 -privkey-file server.key "$ns_domain" 127.0.0.1:443
fi

# Configure iptables rules for IPv4/IPv6
sudo iptables -I INPUT -p udp --dport 5300 -j ACCEPT
sudo iptables -t nat -I PREROUTING -i eth0 -p udp --dport 53 -j REDIRECT --to-ports 5300
sudo ip6tables -I INPUT -p udp --dport 5300 -j ACCEPT
sudo ip6tables -t nat -I PREROUTING -i eth0 -p udp --dport 53 -j REDIRECT --to-ports 5300
lsof -i :5300

echo -e "${YELLOW}Installation and configuration completed!${NC}"
}

# Function to change nameserver
change_nameserver() {
    #!/bin/bash

# Function to change nameserver
change_nameserver() {
    new_ns="$1"
    
    # Extract old PID and kill if exists
    old_pid=$(lsof -i :5300 | awk 'NR==2{print $2}')
    if [ ! -z "$old_pid" ]; then
        echo "Killing old connection with PID: $old_pid"
        kill "$old_pid"
    fi
    
    # Change directory and apply the command again
    cd /root/dnstt/dnstt-server
    if [ "$mode" == "1" ]; then
        screen -dmS slowdns ./dnstt-server -udp :5300 -privkey-file server.key "$new_ns" 127.0.0.1:22
    else
        screen -dmS slowdns ./dnstt-server -udp :5300 -privkey-file server.key "$new_ns" 127.0.0.1:443
    fi
    echo -e "${YELLOW}Nameserver changed to: $new_ns${NC}"
}

}

# Check if the script is being installed or run with commands
if [ $# -eq 0 ]; then
    echo "Please provide a command (installdnstt or setns)."
    exit 1
fi

case "$1" in
    installdnstt)
        install_dnstt
        ;;
    setns)
        if [ $# -ne 2 ]; then
            echo "Usage: $0 setns [new_nameserver_by_user]"
            exit 1
        fi
        change_nameserver "$2"
        ;;
    *)
        echo "Unrecognized command. Usage: $0 (installdnstt | setns [new_nameserver_by_user])"
        exit 1
        ;;
esac
