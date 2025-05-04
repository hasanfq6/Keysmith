#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils/print.sh"
source "$SCRIPT_DIR/utils/crypto.sh"
source "$SCRIPT_DIR/utils/vault.sh"

VAULT_FILE="$SCRIPT_DIR/vault/vault.enc"
TEMP_FILE="/tmp/vault_debug_get.txt"
SERVICE="openai"
ENV="prod"

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

# Check if section exists
SECTION="[$SERVICE:$ENV]"
echo "Looking for section: $SECTION"
if grep -q "^$SECTION$" "$TEMP_FILE"; then
    echo "Section found!"
else
    echo "Section NOT found!"
    echo "Exact grep command: grep -q \"^$SECTION$\" \"$TEMP_FILE\""
    echo "Let's try without anchors:"
    if grep -q "$SECTION" "$TEMP_FILE"; then
        echo "Found without anchors!"
    else
        echo "Not found even without anchors!"
    fi
fi

# Try to extract the key directly
echo "Trying to extract key directly:"
grep -A 10 "$SECTION" "$TEMP_FILE" | grep "key=" | head -n 1

# Clean up
rm -f "$TEMP_FILE"