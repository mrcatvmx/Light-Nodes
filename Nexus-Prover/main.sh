#!/bin/bash

SERVICE_NAME="nexus"
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"

# Display intro and ask for user confirmation
print_intro() {
    f=$(figlet -f starwars Nexus-Prover)
    echo -e "\033[94m$f\033[0m"  # Blue color for the title
    echo -e "\033[92m📡 Running Nexus Prover...\033[0m"  # Green color for the description
    echo -e "\033[96m👨‍💻 Created by: Cipher\033[0m"  # Cyan color for the creator
    echo -e "\033[95m🔍 Initializing Nexus Prover...\033[0m"  # Magenta color for the initializing message
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
    read -p 'Will you F** Nexus-Prover Airdrop? (Y/N): ' answer
    if [[ "${answer,,}" != "y" ]]; then
        echo -e "\033[91mInstallation aborted.\033[0m"
        exit 1
    fi
}

print_intro

# Rust installation script
install_rust() {
    # Define the location where Rust will be installed
    RUSTUP_HOME="$HOME/.rustup"
    CARGO_HOME="$HOME/.cargo"

    # Load Rust environment variables
    load_rust() {
        export RUSTUP_HOME="$HOME/.rustup"
        export CARGO_HOME="$HOME/.cargo"
        export PATH="$CARGO_HOME/bin:$PATH"
        # Source the environment variables for the current session
        if [ -f "$CARGO_HOME/env" ]; then
            source "$CARGO_HOME/env"
        fi
    }

    # Install system dependencies required for Rust
    install_dependencies() {
        echo "Installing system dependencies required for Rust..."
        if command -v apt &> /dev/null; then
            sudo apt update && sudo apt install -y build-essential libssl-dev curl
        elif command -v yum &> /dev/null; then
            sudo yum groupinstall 'Development Tools' && sudo yum install -y openssl-devel curl
        elif command -v dnf &> /dev/null; then
            sudo dnf groupinstall 'Development Tools' && sudo dnf install -y openssl-devel curl
        elif command -v pacman &> /dev/null; then
            sudo pacman -Syu base-devel openssl curl
        else
            echo "Unsupported package manager. Please install dependencies manually."
            exit 1
        fi
    }

    # Install system dependencies before checking for Rust
    install_dependencies

    # Check if Rust is already installed
    if command -v rustup &> /dev/null; then
        echo "Rust is already installed."
        read -p "Do you want to reinstall or update Rust? (y/n): " choice
        if [[ "$choice" == "y" ]]; then
            echo "Reinstalling Rust..."
            rustup self uninstall -y
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        fi
    else
        echo "Rust is not installed. Installing Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    fi

    # Load Rust environment after installation
    load_rust 

    # Fix permissions for Rust directories
    echo "Ensuring correct permissions for Rust directories..."
    if [ -d "$RUSTUP_HOME" ]; then
        sudo chmod -R 755 "$RUSTUP_HOME"
    fi

    if [ -d "$CARGO_HOME" ]; then
        sudo chmod -R 755 "$CARGO_HOME"
    fi

    # Verify Rust and Cargo versions
    rust_version=$(rustc --version)
    cargo_version=$(cargo --version)

    echo "Rust version: $rust_version"
    echo "Cargo version: $cargo_version"

    # Add Rust environment variables to shell profile
    if [[ $SHELL == *"zsh"* ]]; then
        PROFILE="$HOME/.zshrc"
    else
        PROFILE="$HOME/.bashrc"
    fi

    if ! grep -q "CARGO_HOME" "$PROFILE"; then
        echo "Adding Rust environment variables to $PROFILE..."
        {
            echo 'export RUSTUP_HOME="$HOME/.rustup"'
            echo 'export CARGO_HOME="$HOME/.cargo"'
            echo 'export PATH="$CARGO_HOME/bin:$PATH"'
            echo 'source "$CARGO_HOME/env"'
        } >> "$PROFILE"
    fi

    source "$PROFILE"
    source "$CARGO_HOME/env"
}

# Install Rust
install_rust

# Update package list
echo "Updating package list..."
if ! sudo apt update; then
    echo "Failed to update package list."
    exit 1
fi

# Check if Git is installed, if not install it
if ! command -v git &> /dev/null; then
    echo "Git not found. Installing git..."
    if ! sudo apt install git -y; then
        echo "Failed to install Git."
        exit 1
    fi
else
    echo "Git is already installed."
fi

# Clone the Nexus-XYZ network API
if [ -d "$HOME/network-api" ]; then
    echo "Deleting existing Nexus repository..."
    rm -rf "$HOME/network-api"
fi

sleep 3

echo "Cloning Nexus-XYZ network API repository..."
if ! git clone https://github.com/nexus-xyz/network-api.git "$HOME/network-api"; then
    echo "Failed to clone the repository."
    exit 1
fi

cd $HOME/network-api/clients/cli

# Install required dependencies
echo "Installing required dependencies..."
if ! sudo apt install pkg-config libssl-dev -y; then
    echo "Failed to install dependencies."
    exit 1
fi

# Handle existing nexus service
if systemctl is-active --quiet nexus.service; then
    echo "Stopping and disabling the running Nexus service..."
    sudo systemctl stop nexus.service
    sudo systemctl disable nexus.service
else
    echo "Nexus service is not running."
fi

# Create systemd service
echo "Creating systemd service..."
if ! sudo bash -c "cat > $SERVICE_FILE <<EOF
[Unit]
Description=Nexus XYZ Prover Service
After=network.target

[Service]
User=$USER
WorkingDirectory=$HOME/network-api/clients/cli
Environment=NONINTERACTIVE=1
ExecStart=$HOME/.cargo/bin/cargo run --release --bin prover -- beta.orchestrator.nexus.xyz
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF"; then
    echo "Failed to create the systemd service file."
    exit 1
fi

# Reload and start the service
echo "Reloading systemd and starting the Nexus service..."
if ! sudo systemctl daemon-reload; then
    echo "Failed to reload systemd."
    exit 1
fi

if ! sudo systemctl start $SERVICE_NAME.service; then
    echo "Failed to start the Nexus service."
    exit 1
fi

if ! sudo systemctl enable $SERVICE_NAME.service; then
    echo "Failed to enable the Nexus service."
    exit 1
fi

# Show service status
echo "Checking Nexus service status..."
if ! sudo systemctl status $SERVICE_NAME.service; then
    echo "Failed to retrieve service status."
fi

echo "Nexus-Prover installation and service setup is complete!"
