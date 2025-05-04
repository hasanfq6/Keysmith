#!/usr/bin/env bash
# init.sh - Initialize the keysmith vault

# Source the parent script to get access to utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/utils/print.sh"
source "$SCRIPT_DIR/utils/crypto.sh"
source "$SCRIPT_DIR/utils/vault.sh"

# Check if the vault already exists
if [ -f "$VAULT_FILE" ]; then
    print_warning "Vault already exists at $VAULT_FILE"
    read -p "Do you want to reinitialize it? This will erase all stored keys. [y/N] " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_info "Initialization cancelled."
        exit 0
    fi
fi

# Check for encryption tools
check_encryption_tools
if [ $? -ne 0 ]; then
    exit 1
fi

# Set OpenSSL as the default encryption method for better compatibility
ENCRYPTION_METHOD="openssl"

# Make sure VAULT_FILE is set
if [ -z "$VAULT_FILE" ]; then
    VAULT_FILE="$SCRIPT_DIR/vault/vault.enc"
    print_info "Setting vault file to: $VAULT_FILE"
fi

# Create the vault directory if it doesn't exist
mkdir -p "$(dirname "$VAULT_FILE")"

# Create an empty vault file
temp_file=$(create_temp_file "vault_init")
echo "# Keysmith Vault File" > "$temp_file"
echo "# Created: $(date -u)" >> "$temp_file"
echo "# Encryption: $ENCRYPTION_METHOD" >> "$temp_file"
echo "" >> "$temp_file"

# Set up the master password
print_info "Setting up your master password for the vault."
print_info "This password will be used to encrypt and decrypt your API keys."
print_warning "If you forget this password, your stored keys cannot be recovered!"

# Ask for the master password
password=""
while [ -z "$password" ]; do
    read -s -p "Enter master password: " password
    echo
    if [ -z "$password" ]; then
        print_error "Password cannot be empty. Please try again."
        continue
    fi
    
    read -s -p "Confirm master password: " password_confirm
    echo
    
    # Check if passwords match
    if [ "$password" != "$password_confirm" ]; then
        print_error "Passwords do not match. Please try again."
        password=""
        continue
    fi
    
    # Check password strength
    if [ ${#password} -lt 8 ]; then
        print_warning "Password is less than 8 characters. Consider using a stronger password."
        read -p "Continue anyway? [y/N] " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            password=""
            continue
        fi
    fi
done

# Encrypt the empty vault
print_info "Encrypting vault with $ENCRYPTION_METHOD..."
print_info "Input file: $temp_file"
print_info "Output file: $VAULT_FILE"
encrypt_file "$temp_file" "$VAULT_FILE" "$password"

if [ $? -ne 0 ]; then
    print_error "Failed to encrypt the vault."
    secure_delete "$temp_file"
    exit 1
fi

# Create the audit log file
mkdir -p "$(dirname "$AUDIT_LOG")"
echo "# Keysmith Audit Log" > "$AUDIT_LOG"
echo "# Created: $(date -u)" >> "$AUDIT_LOG"
echo "" >> "$AUDIT_LOG"

# Create the config file if it doesn't exist
if [ ! -f "$CONFIG_FILE" ]; then
    mkdir -p "$(dirname "$CONFIG_FILE")"
    cat > "$CONFIG_FILE" << EOF
# Keysmith Configuration
# Created: $(date -u)

# Encryption method (gpg or openssl)
ENCRYPTION_METHOD="$ENCRYPTION_METHOD"

# Vault file location
VAULT_FILE="$VAULT_FILE"

# Audit log location
AUDIT_LOG="$AUDIT_LOG"

# Editor for editing keys
EDITOR="$EDITOR"

# Time to display keys (in seconds)
DISPLAY_TIME=5
EOF
fi

# Clean up
secure_delete "$temp_file"

# Write to audit log
write_audit_log "system" "init" "init"

print_success "Vault initialized successfully!"
print_info "You can now add keys with 'keysmith.sh add'"