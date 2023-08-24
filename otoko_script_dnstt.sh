#!/bin/bash

# Download the first script
wget -O installer.sh "https://raw.githubusercontent.com/Torch121/DNSTT/main/installer.sh"
chmod +x installer.sh

# Download the second script
wget -O setns.sh "https://raw.githubusercontent.com/Torch121/DNSTT/main/setns.sh"
chmod +x setns.sh

# Define the alias for the second script
cat <<EOT >> ~/.bashrc
alias setns="./setns.sh"
EOT

# Reload the bashrc file
source ~/.bashrc

# Inform the user
echo "Scripts downloaded and first script executed."
echo "To start the second script, use the alias 'setns'."
