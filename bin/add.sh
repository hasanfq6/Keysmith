#!/usr/bin/env bash
# add.sh - Add a new API key to the vault

# Source the parent script to get access to utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/utils/print.sh"
source "$SCRIPT_DIR/utils/crypto.sh"
source "$SCRIPT_DIR/utils/vault.sh"

# Parse arguments
service=""
env=""
key=""
desc=""
tags=""

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
        --key)
            key="$2"
            shift 2
            ;;
        --desc)
            desc="$2"
            shift 2
            ;;
        --tags)
            tags="$2"
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
    read -p "Enter service name (e.g., openai, aws): " service
fi

if [ -z "$env" ]; then
    read -p "Enter environment (e.g., prod, dev): " env
fi

if [ -z "$key" ]; then
    read -s -p "Enter API key: " key
    echo
fi

if [ -z "$desc" ]; then
    read -p "Enter description (optional): " desc
fi

if [ -z "$tags" ]; then
    read -p "Enter tags (comma-separated, optional): " tags
fi

# Ensure we have valid data
if [ -z "$key" ]; then
    print_error "API key cannot be empty"
    exit 1
fi

# Swap variables if they were entered in the wrong order
# This is a temporary fix for the current input handling
if [[ "$key" == "password"* && "$desc" == "sk-"* ]]; then
    print_info "Detected password in key field and API key in description field. Swapping values."
    temp_key="$key"
    key="$desc"
    desc="$temp_key"
fi

# Create a temporary file for decryption
temp_file=$(create_temp_file "vault_add")

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

# Check if the key already exists
if grep -q "^\[$service:$env\]$" "$temp_file"; then
    read -p "Key for $service:$env already exists. Do you want to overwrite it? [y/N] " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_info "Addition cancelled."
        secure_delete "$temp_file"
        exit 0
    fi
fi

# Debug output
print_info "Adding key with the following details:"
print_info "Service: $service"
print_info "Environment: $env"
print_info "Key: [REDACTED]"
print_info "Description: $desc"
print_info "Tags: $tags"

# Add the key to the vault
add_key_to_vault "$service" "$env" "$key" "$desc" "$tags" "$temp_file"

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
write_audit_log "$service" "$env" "add"

print_success "API key for $service:$env added successfully!"