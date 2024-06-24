#!/bin/bash

# Display CA logo and welcome message
echo "Showing CA logo..."
echo '════════════════════════════════════════════════════════════'
echo '║       Welcome to Nubit BOT!                             ║'
echo '║                                                            ║'
echo '║     Follow us on Twitter:                                  ║'
echo '║     https://twitter.com/cipher_airdrop                     ║'
echo '║                                                            ║'
echo '║     Join us on Telegram:                                   ║'
echo '║     - https://t.me/+tFmYJSANTD81MzE1                       ║'
echo '╚════════════════════════════════════════════════════════════'

# Prompt the user for input
read -p 'Will you Continue Nubit light Node by Installing? (Y/N): ' answer
if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
    echo 'Aborting installation.'
    exit 1
fi

# Wait for 2 seconds
sleep 2

# Install tmux if not already installed
sudo apt update
sudo apt install -y tmux

# Remove any existing nubit-node directory (optional cleanup)
rm -rf nubit-node

# Start a new tmux session and run the Nubit installation script
tmux new-session -d -s "Light_Node_nubit" "curl -sL1 https://nubit.sh/ | bash"

# Notify the user that the script has completed and the tmux session is detached
echo "Nubit light node installation started in tmux session 'Light_Node_nubit'."
echo "You can reattach to this session using: tmux attach-session -t Light_Node_nubit"
echo "Script execution completed successfully."

# Credits
echo "This script was made by CIPHER_NODE."
