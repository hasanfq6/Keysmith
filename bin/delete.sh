#!/usr/bin/env bash
# delete.sh - Delete an API key from the vault

# Source the parent script to get access to utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/utils/print.sh"
source "$SCRIPT_DIR/utils/crypto.sh"
source "$SCRIPT_DIR/utils/vault.sh"

# Parse arguments
service=""
env=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --service)
            service="$2"
            shift 2
            ;;
        --env)
            env="$2"
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

# Validate required parameters
if [ -z "$service" ]; then
    read -p "Enter service name: " service
fi

if [ -z "$env" ]; then
    read -p "Enter environment: " env
fi

# Create a temporary file for decryption
temp_file=$(create_temp_file "vault_delete")

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

# Confirm deletion
read -p "Are you sure you want to delete the key for $service:$env? [y/N] " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    print_info "Deletion cancelled."
    secure_delete "$temp_file"
    exit 0
fi

# Delete the key from the vault
delete_key_from_vault "$service" "$env" "$temp_file"

if [ $? -ne 0 ]; then
    secure_delete "$temp_file"
    exit 1
fi

# Encrypt the vault again
print_info "Encrypting vault..."
encrypt_file "$temp_file" "$VAULT_FILE" "$password"

if [ $? -ne 0 ]; then
    print_error "Failed to encrypt the vault."
    secure_delete "$temp_file"
    exit 1
fi

# Clean up
secure_delete "$temp_file"

# Write to audit log
write_audit_log "$service" "$env" "delete"

print_success "API key for $service:$env deleted successfully!"