#!/usr/bin/env bash
# edit.sh - Edit an existing API key in the vault

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
temp_file=$(create_temp_file "vault_edit")

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

# Check if the key exists
if ! grep -q "^\[$service:$env\]$" "$temp_file"; then
    print_error "Key not found for service '$service' and environment '$env'"
    secure_delete "$temp_file"
    exit 1
fi

# Create a temporary file for editing
edit_file=$(create_temp_file "vault_edit_section")

# Extract the section to edit
section_start=$(grep -n "^\[$service:$env\]$" "$temp_file" | cut -d':' -f1)
section_end=$(tail -n +$((section_start+1)) "$temp_file" | grep -n "^\[.*\]$" | head -n 1 | cut -d':' -f1)

if [ -z "$section_end" ]; then
    # If no next section, use the end of file
    section_end=$(wc -l < "$temp_file")
else
    # Adjust for the tail offset
    section_end=$((section_start + section_end))
fi

# Extract the section to edit
sed -n "${section_start},${section_end}p" "$temp_file" > "$edit_file"

# Add instructions at the top of the file
cat > "${edit_file}.tmp" << EOF
# Edit the key information below
# DO NOT change the section header [$service:$env]
# Lines starting with # will be ignored
#
# Format:
# key=your_api_key
# desc=description of the key
# created=YYYY-MM-DD (do not change)
# expires=YYYY-MM-DD (optional)
# tags=comma,separated,tags

EOF

cat "$edit_file" >> "${edit_file}.tmp"
mv "${edit_file}.tmp" "$edit_file"

# Open the editor
print_info "Opening editor to edit the key..."
# Use the configured editor or fall back to vi
if [ -z "$EDITOR" ]; then
    if command -v nano >/dev/null 2>&1; then
        EDITOR="nano"
    elif command -v vim >/dev/null 2>&1; then
        EDITOR="vim"
    elif command -v vi >/dev/null 2>&1; then
        EDITOR="vi"
    else
        print_error "No suitable editor found (nano, vim, or vi). Please set EDITOR environment variable."
        secure_delete "$temp_file"
        secure_delete "$edit_file"
        exit 1
    fi
fi
$EDITOR "$edit_file" || {
    print_error "Failed to open editor. Please set EDITOR environment variable."
    secure_delete "$temp_file"
    secure_delete "$edit_file"
    exit 1
}

# Check if the file was modified
if [ ! -s "$edit_file" ]; then
    print_error "Edit file is empty. Aborting."
    secure_delete "$temp_file"
    secure_delete "$edit_file"
    exit 1
fi

# Remove comment lines
grep -v "^#" "$edit_file" > "${edit_file}.tmp"
mv "${edit_file}.tmp" "$edit_file"

# Check if the section header is still there
if ! grep -q "^\[$service:$env\]$" "$edit_file"; then
    print_error "Section header [$service:$env] was removed. Aborting."
    secure_delete "$temp_file"
    secure_delete "$edit_file"
    exit 1
fi

# Create a new vault file with the edited section
awk -v start="$section_start" -v end="$section_end" -v edit_file="$edit_file" '
    BEGIN { line_num = 1; }
    line_num < start { print; }
    line_num == start { system("cat " edit_file); }
    line_num > end { print; }
    { line_num++; }
' "$temp_file" > "${temp_file}.new"

# Replace the old vault file
mv "${temp_file}.new" "$temp_file"

# Encrypt the vault again
print_info "Encrypting vault..."
encrypt_file "$temp_file" "$VAULT_FILE" "$password"

if [ $? -ne 0 ]; then
    print_error "Failed to encrypt the vault."
    secure_delete "$temp_file"
    secure_delete "$edit_file"
    exit 1
fi

# Clean up
secure_delete "$temp_file"
secure_delete "$edit_file"

# Write to audit log
write_audit_log "$service" "$env" "edit"

print_success "API key for $service:$env edited successfully!"