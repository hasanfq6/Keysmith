#!/usr/bin/env bash
# list.sh - List all API keys in the vault

# Source the parent script to get access to utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/utils/print.sh"
source "$SCRIPT_DIR/utils/crypto.sh"
source "$SCRIPT_DIR/utils/vault.sh"

# Parse arguments
filter=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --filter)
            filter="$2"
            shift 2
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Make sure VAULT_FILE is set
if [ -z "$VAULT_FILE" ]; then
    VAULT_FILE="$SCRIPT_DIR/vault/vault.enc"
    print_info "Setting vault file to: $VAULT_FILE"
fi

# Check if the vault exists
if [ ! -f "$VAULT_FILE" ]; then
    print_error "Vault not found at $VAULT_FILE. Please initialize it first with 'keysmith.sh init'"
    exit 1
fi

# Create a temporary file for decryption
temp_file=$(create_temp_file "vault_list")

# Ask for the master password
read -s -p "Enter master password: " password
echo

# Decrypt the vault
print_info "Decrypting vault..."
decrypt_file "$VAULT_FILE" "$temp_file" "$password"

if [ $? -ne 0 ]; then
    print_error "Failed to decrypt the vault. Incorrect password?"
    secure_delete "$temp_file"
    exit 1
fi

# List all keys in the vault
list_keys_from_vault "$temp_file" "$filter"

# Clean up
secure_delete "$temp_file"

# Write to audit log
write_audit_log "system" "list" "list"