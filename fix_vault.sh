#!/usr/bin/env bash
# fix_vault.sh - Fix the vault by swapping key and description

# Source the parent script to get access to utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils/print.sh"
source "$SCRIPT_DIR/utils/crypto.sh"
source "$SCRIPT_DIR/utils/vault.sh"

# Set the vault file path
VAULT_FILE="$SCRIPT_DIR/vault/vault.enc"

# Get the password
read -s -p "Enter vault password: " password
echo

# Create a temporary file for decryption
temp_file=$(create_temp_file "vault_fix")

# Decrypt the vault
decrypt_file "$VAULT_FILE" "$temp_file" "$password"

# Create a fixed vault file
fixed_file=$(create_temp_file "vault_fixed")

# Copy the header
grep -A 3 "^# Keysmith Vault File" "$temp_file" > "$fixed_file"
echo "" >> "$fixed_file"

# Fix each section
while IFS= read -r line; do
    if [[ "$line" =~ ^\[.*\]$ ]]; then
        # This is a section header
        section="$line"
        echo "$section" >> "$fixed_file"
        
        # Get the key and description
        key_line=$(grep -A 1 "^$section$" "$temp_file" | grep "^key=" | head -n 1)
        desc_line=$(grep -A 2 "^$section$" "$temp_file" | grep "^desc=" | head -n 1)
        created_line=$(grep -A 3 "^$section$" "$temp_file" | grep "^created=" | head -n 1)
        expires_line=$(grep -A 4 "^$section$" "$temp_file" | grep "^expires=" | head -n 1)
        tags_line=$(grep -A 5 "^$section$" "$temp_file" | grep "^tags=" | head -n 1)
        
        # Extract values
        key_value=$(echo "$key_line" | cut -d'=' -f2-)
        desc_value=$(echo "$desc_line" | cut -d'=' -f2-)
        
        # Swap key and description
        echo "key=$desc_value" >> "$fixed_file"
        echo "desc=$key_value" >> "$fixed_file"
        echo "$created_line" >> "$fixed_file"
        echo "$expires_line" >> "$fixed_file"
        echo "$tags_line" >> "$fixed_file"
        echo "" >> "$fixed_file"
    fi
done < <(grep -E "^\[.*\]$" "$temp_file")

# Encrypt the fixed vault
encrypt_file "$fixed_file" "$VAULT_FILE" "$password"

print_success "Vault fixed successfully!"

# Clean up
rm -f "$temp_file" "$fixed_file"