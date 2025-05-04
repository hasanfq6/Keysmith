#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils/print.sh"
source "$SCRIPT_DIR/utils/crypto.sh"

VAULT_FILE="$SCRIPT_DIR/vault/vault.enc"
TEMP_FILE="/tmp/vault_debug.txt"

# Ask for the master password
read -s -p "Enter master password: " password
echo

# Set encryption method
export ENCRYPTION_METHOD="openssl"

# Decrypt the vault
echo "Decrypting vault..."
decrypt_file "$VAULT_FILE" "$TEMP_FILE" "$password"

if [ $? -ne 0 ]; then
    echo "Failed to decrypt the vault. Incorrect password?"
    exit 1
fi

# Display the content
echo "Vault content:"
echo "--------------------"
cat "$TEMP_FILE"
echo "--------------------"

# Clean up
rm -f "$TEMP_FILE"