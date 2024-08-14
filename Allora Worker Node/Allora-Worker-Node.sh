#!/bin/bash

# Function to display the styled message
display_message() {
  echo -e "\e[36m╔═════════════════════════════════════════════════════════════════╗"
  echo -e "║    Welcome to Allora W0rker-N0de Auto Setup B0T💀                 ║"
  echo -e "║                                                                   ║"
  echo -e "║     Follow us on (X)Twitter:                                      ║"
  echo -e "║     https://twitter.com/cipher_airdrop                            ║"
  echo -e "║                                                                   ║"
  echo -e "║     Join us on Telegram:                                          ║"
  echo -e "║       - https://t.me/+tFmYJSANTD81MzE1                            ║"
  echo -e "╚═════════════════════════════════════════════════════════════════╝\e[0m"
}

# Display the styled message at the beginning
display_message

# Check if re-running after logout
if [ -f ~/.docker_setup_stage ]; then
  stage=$(cat ~/.docker_setup_stage)
else
  stage="start"
fi

# Update and Upgrade
if [ "$stage" == "start" ]; then
  sudo apt update && sudo apt upgrade -y

  # Install Dependencies
  sudo apt install -y ca-certificates zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev curl git wget make jq build-essential pkg-config lsb-release libssl-dev libreadline-dev libffi-dev gcc screen unzip lz4 python3 python3-pip

  # Check if Docker is installed
  if ! command -v docker &> /dev/null; then
    # Install Docker
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
    docker version

    # Docker Permission
    sudo groupadd docker || true
    sudo usermod -aG docker $USER
  else
    echo -e "\e[32mDocker is already installed.\e[0m"
  fi

  # Check if Docker Compose is installed
  if ! command -v docker-compose &> /dev/null; then
    # Install Docker Compose
    VER=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
    sudo curl -L "https://github.com/docker/compose/releases/download/$VER/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    docker-compose --version
  else
    echo -e "\e[32mDocker Compose is already installed.\e[0m"
  fi

  echo "docker" > ~/.docker_setup_stage

  # Notify user to log out and back in
  echo -e "\e[31mPlease log out and log back in to apply Docker group changes.\e[0m"
  echo -e "\e[31mThen, re-run this script to continue the setup.\e[0m"

  # Stop script execution for manual action
  exit 0
fi

if [ "$stage" == "docker" ]; then
  # Ask the user if they've run Allora before
  echo -e "\e[33mHave you run this Allora setup before? (yes/no)\e[0m"
  read -r has_run_before

  if [ "$has_run_before" == "yes" ]; then
    # Delete old files
    cd $HOME && cd basic-coin-prediction-node
    docker compose down -v
    docker container prune -f
    cd $HOME && rm -rf basic-coin-prediction-node

    # Clone worker repo
    git clone https://github.com/allora-network/basic-coin-prediction-node
    cd basic-coin-prediction-node

    # Install nano editor
    sudo apt install nano -y

    # Request wallet phrases
    echo -e "\e[33mPlease enter your wallet seed phrase:\e[0m"
    read -r wallet_phrases

    # Configure worker
    rm -rf config.json
    cat <<EOF > config.json
{
    "wallet": {
        "addressKeyName": "testkey",
        "addressRestoreMnemonic": "$wallet_phrases",
        "alloraHomeDir": "",
        "gas": "1000000",
        "gasAdjustment": 1.0,
        "nodeRpc": "https://sentries-rpc.testnet-1.testnet.allora.network/",
        "maxRetries": 1,
        "delay": 1,
        "submitTx": false
    },
    "worker": [
        {
            "topicId": 1,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 5,
            "parameters": {
                "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                "Token": "ETH"
            }
        },
        {
            "topicId": 2,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 5,
            "parameters": {
                "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                "Token": "ETH"
            }
        },
        {
            "topicId": 7,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 5,
            "parameters": {
                "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                "Token": "ETH"
            }
        }
    ]
}
EOF

    # Launch the worker
    chmod +x init.config
    ./init.config

    # Modify model.py
    nano model.py

    # Change the intervals
    sed -i 's/intervals = .*/intervals = ["10m", "20m", "1h", "1d"]/' model.py

    # Launch docker
    docker compose up -d --build

  elif [ "$has_run_before" == "no" ]; then
    # Install Go
    sudo rm -rf /usr/local/go
    curl -L https://go.dev/dl/go1.22.4.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
    echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile
    echo 'export PATH=$PATH:$(go env GOPATH)/bin' >> $HOME/.bash_profile
    source $HOME/.bash_profile
    go version

    # Install Python3 and pip
    sudo apt install python3 python3-pip -y
    python3 --version

    # Install Allorad: Wallet
    git clone https://github.com/allora-network/allora-chain.git
    cd allora-chain && make all
    allorad keys add testkey --recover

    # Start from making a worker clone
    cd $HOME
    git clone https://github.com/allora-network/basic-coin-prediction-node
    cd basic-coin-prediction-node
    sudo apt install nano -y

    # Request wallet phrases
    echo -e "\e[33mPlease enter your wallet seed phrase:\e[0m"
    read -r wallet_phrases

    # Configure worker
    rm -rf config.json
    cat <<EOF > config.json
{
    "wallet": {
        "addressKeyName": "testkey",
        "addressRestoreMnemonic": "$wallet_phrases",
        "alloraHomeDir": "",
        "gas": "1000000",
        "gasAdjustment": 1.0,
        "nodeRpc": "https://sentries-rpc.testnet-1.testnet.allora.network/",
        "maxRetries": 1,
        "delay": 1,
        "submitTx": false
    },
    "worker": [
        {
            "topicId": 1,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 5,
            "parameters": {
                "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                "Token": "ETH"
            }
        },
        {
            "topicId": 2,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 5,
            "parameters": {
                "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                "Token": "ETH"
            }
        },
        {
            "topicId": 7,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 5,
            "parameters": {
                "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                "Token": "ETH"
            }
        }
    ]
}
EOF

    # Launch the worker
    chmod +x init.config
    ./init.config

    # Modify model.py
    nano model.py

    # Change the intervals
    sed -i 's/intervals = .*/intervals = ["10m", "20m", "1h", "1d"]/' model.py

    # Launch docker
    docker compose up -d --build
  else
    echo -e "\e[31mInvalid input. Please enter 'yes' or 'no'.\e[0m"
    exit 1
  fi
fi
