#!/bin/bash

# --- Utility Functions ---
error_exit() {
    echo "Error: $1" >&2
    exit 1
}

# --- Core Logic Functions ---

install_cloudflared() {
    echo "Select your operating system for cloudflared installation:"
    echo "  1) Termux"
    echo "  2) macOS"
    read -p "Enter your choice [1-2]: " choice

    case $choice in
        1)
            echo "Running installation for Termux..."
            command -v wget >/dev/null || { echo "Installing wget..."; pkg install -y wget || error_exit "Failed to install wget."; }
            
            ARCH="arm"
            case $(uname -m) in
                aarch64) ARCH="arm64" ;;
                x86_64) ARCH="amd64" ;;
            esac

            echo "[+] Downloading cloudflared for ${ARCH}..."
            wget "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${ARCH}" -O cloudflared || error_exit "Failed to download cloudflared."
            
            chmod +x cloudflared
            mv cloudflared "$PREFIX/bin/" || error_exit "Failed to move cloudflared."
            ;;
        2)
            echo "Running installation for macOS..."
            command -v brew >/dev/null || error_exit "Homebrew not found. Please install it from https://brew.sh/"
            
            echo "Installing cloudflared with Homebrew..."
            brew install cloudflare/cloudflare/cloudflared || error_exit "Failed to install cloudflared."
            ;;
        *)
            echo "Invalid choice. Returning to main menu."
            return
            ;;
    esac

    echo ""
    echo "Verifying installation..."
    if command -v cloudflared &> /dev/null; then
        echo "[✔] cloudflared installed successfully. Version:"
        cloudflared --version
        
        # Create domains directory
        mkdir -p "$HOME/.cloudflared/domains"
        echo "[✔] Created domains configuration directory at ~/.cloudflared/domains"
    else
        error_exit "Installation failed or cloudflared is not in your PATH."
    fi
}

uninstall_cloudflared() {
    echo "Uninstalling cloudflared..."
    if command -v brew &> /dev/null && brew list cloudflared &>/dev/null; then
        echo "Uninstalling via Homebrew..."
        brew uninstall cloudflare/cloudflare/cloudflared
    elif [ -n "$PREFIX" ] && [ -f "$PREFIX/bin/cloudflared" ]; then
        echo "Uninstalling from Termux..."
        rm "$PREFIX/bin/cloudflared"
    else
        local CLOUDFLARED_PATH=$(command -v cloudflared)
        echo "Attempting to remove cloudflared from $CLOUDFLARED_PATH..."
        rm "$CLOUDFLARED_PATH"
    fi

    if ! command -v cloudflared &> /dev/null; then
        echo "[✔] cloudflared uninstalled successfully."
    else
        error_exit "Failed to uninstall cloudflared. Please do it manually."
    fi
}

# --- Main Menu ---
while true; do
    echo ""
    # Check if cloudflared is installed and show a dynamic menu
    if command -v cloudflared &> /dev/null; then
        VERSION=$(cloudflared --version)
        echo "Cloudflared is installed ($VERSION)"
        echo "--------------------------"
        echo "1. Uninstall cloudflared"
        echo "2. Exit"
        read -p "Enter your choice [1-2]: " menu_choice

        case $menu_choice in
            1) uninstall_cloudflared ;;
            2) echo "Exiting."; exit 0 ;;
            *) echo "Invalid option. Please try again." ;;
        esac
    else
        echo "Cloudflared is not installed."
        echo "--------------------------"
        echo "1. Install cloudflared"
        echo "2. Exit"
        read -p "Enter your choice [1-2]: " menu_choice

        case $menu_choice in
            1) install_cloudflared ;;
            2) echo "Exiting."; exit 0 ;;
            *) echo "Invalid option. Please try again." ;;
        esac
    fi
done
