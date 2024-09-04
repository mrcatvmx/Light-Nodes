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
  # Ask the user if they've run Allora worker node before
  echo -e "\e[33mHave you run this Allora worker node setup before? (yes/no)\e[0m"
  read -r has_run_before

  if [ "$has_run_before" == "yes" ]; then
    # Stop and remove old nodes
    cd $HOME && cd basic-coin-prediction-node
    docker compose down -v
    docker container prune -f
    cd $HOME && rm -rf basic-coin-prediction-node

    # Clone and configure HuggingFace worker
    cd $HOME
    git clone https://github.com/allora-network/allora-huggingface-walkthrough
    cd allora-huggingface-walkthrough
    mkdir -p worker-data
    chmod -R 777 worker-data
    cp config.example.json config.json

    # Request wallet seed phrase
    echo -e "\e[33mPlease enter your wallet seed phrase:\e[0m"
    read -r wallet_phrases

    # Replace wallet seed phrase in config and include topics
    cat <<EOF > config.json
{
    "wallet": {
        "addressKeyName": "testkey",
        "addressRestoreMnemonic": "$wallet_phrases",
        "alloraHomeDir": "/root/.allorad",
        "gas": "1000000",
        "gasAdjustment": 1.0,
        "nodeRpc": "https://allora-rpc.testnet.allora.network/",   # Updated RPC URL
        "maxRetries": 1,
        "delay": 1,
        "submitTx": false
    },
    "worker": [
        {
            "topicId": 1,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 1,
            "parameters": {
                "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                "Token": "ETH"
            }
        },
        {
            "topicId": 2,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 3,
            "parameters": {
                "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                "Token": "ETH"
            }
        },
        {
            "topicId": 3,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 5,
            "parameters": {
                "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                "Token": "BTC"
            }
        },
        {
            "topicId": 4,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 2,
            "parameters": {
                "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                "Token": "BTC"
            }
        },
        {
            "topicId": 5,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 4,
            "parameters": {
                "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                "Token": "SOL"
            }
        },
        {
            "topicId": 6,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 5,
            "parameters": {
                "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                "Token": "SOL"
            }
        },
        {
            "topicId": 7,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 2,
            "parameters": {
                "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                "Token": "ETH"
            }
        },
        {
            "topicId": 8,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 3,
            "parameters": {
                "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                "Token": "BNB"
            }
        },
        {
            "topicId": 9,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 5,
            "parameters": {
                "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                "Token": "ARB"
            }
        }
    ]
}
EOF

    # Replace testkey with the wallet name
    wallet_name=$(allorad keys list | grep -o 'testkey')
    sed -i "s/testkey/$wallet_name/g" config.json

    # Prompt to replace Coingecko API in app.py
    echo -e "\e[33mPlease update the Coingecko API in app.py as needed. The file will now open for editing.\e[0m"
    nano app.py

    # Run Huggingface Worker
    chmod +x init.config
    ./init.config
    docker compose up --build -d

  elif [ "$has_run_before" == "no" ]; then
    # Start from scratch
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

    # Clone and configure HuggingFace worker
    cd $HOME
    git clone https://github.com/allora-network/allora-huggingface-walkthrough
    cd allora-huggingface-walkthrough
    mkdir -p worker-data
    chmod -R 777 worker-data
    cp config.example.json config.json

    # Request wallet seed phrase
    echo -e "\e[33mPlease enter your wallet seed phrase:\e[0m"
    read -r wallet_phrases

    # Replace wallet seed phrase in config and include topics
    cat <<EOF > config.json
{
    "wallet": {
        "addressKeyName": "testkey",
        "addressRestoreMnemonic": "$wallet_phrases",
        "alloraHomeDir": "/root/.allorad",
        "gas": "1000000",
        "gasAdjustment": 1.0,
        "nodeRpc": "https://allora-rpc.testnet.allora.network/",   # Updated RPC URL
        "maxRetries": 1,
        "delay": 1,
        "submitTx": false
    },
    "worker": [
        {
            "topicId": 1,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 1,
            "parameters": {
                "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                "Token": "ETH"
            }
        },
        {
            "topicId": 2,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 3,
            "parameters": {
                "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                "Token": "ETH"
            }
        },
        {
            "topicId": 3,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 5,
            "parameters": {
                "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                "Token": "BTC"
            }
        },
        {
            "topicId": 4,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 2,
            "parameters": {
                "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                "Token": "BTC"
            }
        },
        {
            "topicId": 5,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 4,
            "parameters": {
                "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                "Token": "SOL"
            }
        },
        {
            "topicId": 6,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 5,
            "parameters": {
                "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                "Token": "SOL"
            }
        },
        {
            "topicId": 7,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 2,
            "parameters": {
                "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                "Token": "ETH"
            }
        },
        {
            "topicId": 8,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 3,
            "parameters": {
                "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                "Token": "BNB"
            }
        },
        {
            "topicId": 9,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 5,
            "parameters": {
                "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                "Token": "ARB"
            }
        }
    ]
}
EOF

    # Replace testkey with the wallet name
    wallet_name=$(allorad keys list | grep -o 'testkey')
    sed -i "s/testkey/$wallet_name/g" config.json

    # Prompt to replace Coingecko API in app.py
    echo -e "\e[33mPlease update the Coingecko API in app.py as needed. The file will now open for editing.\e[0m"
    nano app.py

    # Run Huggingface Worker
    chmod +x init.config
    ./init.config
    docker compose up --build -d

  else
    echo -e "\e[31mInvalid input. Please enter 'yes' or 'no'.\e[0m"
    exit 1
  fi
fi
