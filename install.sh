#!/usr/bin/env bash
# install.sh - Install keysmith to the system

set -e

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default installation directory
INSTALL_DIR="/data/data/com.termux/files/usr/bin/"   #$HOME/.local/bin"
CONFIG_DIR="$HOME/.config/keysmith"

# Print functions
print_info() {
    echo -e "\033[0;34m[INFO]\033[0m $1"
}

print_success() {
    echo -e "\033[0;32m[SUCCESS]\033[0m $1"
}

print_error() {
    echo -e "\033[0;31m[ERROR]\033[0m $1" >&2
}

# Check if the script is being run with sudo
if [ "$(id -u)" -eq 0 ]; then
    INSTALL_DIR="/usr/local/bin"
    CONFIG_DIR="/etc/keysmith"
    print_info "Running as root, will install to $INSTALL_DIR"
fi

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --prefix)
            INSTALL_DIR="$2/bin"
            CONFIG_DIR="$2/etc/keysmith"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --prefix DIR    Install to DIR/bin instead of $INSTALL_DIR"
            echo "  --help          Show this help message"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Create installation directories
mkdir -p "$INSTALL_DIR"
mkdir -p "$CONFIG_DIR"
mkdir -p "$CONFIG_DIR/vault"
mkdir -p "$CONFIG_DIR/tmp"

# Make the script executable
chmod +x "$SCRIPT_DIR/keysmith.sh"
chmod +x "$SCRIPT_DIR/bin"/*.sh

# Copy files
print_info "Installing keysmith to $INSTALL_DIR..."

# Create a wrapper script
cat > "$INSTALL_DIR/keysmith" << EOF
#!/usr/bin/env bash
# Keysmith wrapper script

# Set the keysmith directory
export KEYSMITH_DIR="$CONFIG_DIR"

# Run the actual script
exec "$CONFIG_DIR/keysmith.sh" "\$@"
EOF

chmod +x "$INSTALL_DIR/keysmith"

# Copy the main script and directories
cp -r "$SCRIPT_DIR/keysmith.sh" "$CONFIG_DIR/"
cp -r "$SCRIPT_DIR/bin" "$CONFIG_DIR/"
cp -r "$SCRIPT_DIR/utils" "$CONFIG_DIR/"

# Create config file if it doesn't exist
if [ ! -f "$CONFIG_DIR/config/keysmith.conf" ]; then
    mkdir -p "$CONFIG_DIR/config"
    cat > "$CONFIG_DIR/config/keysmith.conf" << EOF
# Keysmith Configuration
# Created: $(date -u)

# Encryption method (gpg or openssl)
ENCRYPTION_METHOD="gpg"

# Vault file location
VAULT_FILE="$CONFIG_DIR/vault/vault.enc"

# Audit log location
AUDIT_LOG="$CONFIG_DIR/vault/audit.log"

# Editor for editing keys
EDITOR="nano"

# Time to display keys (in seconds)
DISPLAY_TIME=5
EOF
fi

# Update the main script to use the config directory
sed -i "s|SCRIPT_DIR=\"\$(cd \"\$(dirname \"\${BASH_SOURCE\[0\]}\")\" \&\& pwd)\"|SCRIPT_DIR=\"\${KEYSMITH_DIR:-\$(cd \"\$(dirname \"\${BASH_SOURCE\[0\]}\")\" \&\& pwd)}\"|g" "$CONFIG_DIR/keysmith.sh"

print_success "Keysmith installed successfully!"
print_info "You can now run 'keysmith' from anywhere."

# Check if the installation directory is in PATH
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    print_info "Make sure $INSTALL_DIR is in your PATH."
    print_info "You may need to add the following to your ~/.bashrc or ~/.zshrc:"
    echo "export PATH=\"\$PATH:$INSTALL_DIR\""
fi
