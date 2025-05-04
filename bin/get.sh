#!/usr/bin/env bash
# get.sh - Retrieve an API key from the vault

# Source the parent script to get access to utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/utils/print.sh"
source "$SCRIPT_DIR/utils/crypto.sh"
source "$SCRIPT_DIR/utils/vault.sh"

# Parse arguments
service=""
env=""
show_metadata=0
DISPLAY_TIME=5  # Default display time in seconds

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
        --metadata)
            show_metadata=1
            shift
            ;;
        --time)
            DISPLAY_TIME="$2"
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
temp_file=$(create_temp_file "vault_get")

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

# Get the key from the vault
if [ $show_metadata -eq 1 ]; then
    # Show all metadata
    metadata=$(get_key_metadata "$service" "$env" "$temp_file")
    
    if [ $? -eq 0 ]; then
        echo -e "${CYAN}Metadata for $service:$env${RESET}"
        echo "----------------------------------------"
        echo "$metadata" | while IFS= read -r line; do
            key=$(echo "$line" | cut -d'=' -f1)
            value=$(echo "$line" | cut -d'=' -f2-)
            
            # Don't display the actual key value
            if [ "$key" = "key" ]; then
                echo -e "${YELLOW}$key${RESET}=<hidden>"
            else
                echo -e "${YELLOW}$key${RESET}=$value"
            fi
        done
    fi
else
    # Get just the key
    key=$(get_key_from_vault "$service" "$env" "$temp_file")
    
    if [ $? -eq 0 ]; then
        # Display the key for a limited time
        display_key_timed "$key" "$DISPLAY_TIME"
    fi
fi

# Clean up
secure_delete "$temp_file"

# Write to audit log
write_audit_log "$service" "$env" "get"

if [ $show_metadata -eq 0 ]; then
    print_info "To see metadata, use --metadata flag"
fi