#!/bin/bash

set -e

# Function to run commands and check for errors
run_command() {
  eval "$1"
  if [ $? -ne 0 ]; then
    echo "Error: Command failed - $1"
    exit 1
  fi
}

# Check and install figlet if not installed
if ! command -v figlet &> /dev/null; then
  echo -e "\033[1m\033[34mInstalling figlet...\033[0m"
  run_command 'sudo apt update'
  run_command 'sudo apt install -y figlet'
  echo "Figlet installed successfully."
fi

# Check and install the starwars font for figlet
if [ ! -f /usr/share/figlet/starwars.flf ]; then
  echo -e "\033[1m\033[34mDownloading and installing the starwars font for figlet...\033[0m"
  sudo wget -P /usr/share/figlet/ http://www.figlet.org/fonts/starwars.flf
  echo "Starwars font installed successfully."
fi

# Function to print the introduction
print_intro() {
  echo -e "\033[94m"
  figlet -f /usr/share/figlet/starwars.flf "Sonaric B0T"
  echo -e "\033[0m"

  echo -e "\033[92m📡 Farming Sonaric_N0de\033[0m"   # Green color for the description
  echo -e "\033[96m👨‍💻 Created by: Cipher\033[0m"  # Cyan color for the creator
  echo -e "\033[95m🔍 Initializing Sonaric B0T...\033[0m"  # Magenta color for the initializing message
  echo "════════════════════════════════════════════════════════════"
  echo "║       Follow us for updates and support:                 ║"
  echo "║                                                          ║"
  echo "║     Twitter:                                             ║"
  echo "║     https://twitter.com/cipher_airdrop                   ║"
  echo "║                                                          ║"
  echo "║     Telegram:                                            ║"
  echo "║     - https://t.me/+tFmYJSANTD81MzE1                     ║"
  echo "╚════════════════════════════════════════════════════════════"

  # Prompt for user confirmation
  read -p "$(echo -e '\033[91mWill you F** Sonaric Airdrop? (Y/N): \033[0m')" answer  # Red color for the prompt
  if [[ "$answer" != "Y" && "$answer" != "y" ]]; then
    echo -e "\033[91mAborting installation.\033[0m"  # Red color for abort message
    exit 1
  fi
}

# Call the introduction function
print_intro

# Update package repositories and upgrade existing packages
sudo apt-get update && sudo apt-get upgrade -y

# Clear the screen
clear

# Download and execute the installation script
sh -c "$(curl -fsSL https://raw.githubusercontent.com/monk-io/sonaric-install/main/linux-install-sonaric.sh)"

# Confirm that the node is running
sonaric node-info

# Backup Node Keys
sonaric identity-export -o mysonaric.identity
