#!/usr/bin/env bash
# vault.sh - Vault management utilities for keysmith

# Create a temporary file
create_temp_file() {
    local prefix="${1:-keysmith}"
    
    # Ensure the tmp directory exists
    mkdir -p "$SCRIPT_DIR/tmp"
    
    if command -v mktemp >/dev/null 2>&1; then
        local temp_file=$(mktemp -t "${prefix}.XXXXXX" 2>/dev/null || mktemp "/tmp/${prefix}.XXXXXX")
        echo "$temp_file"
    else
        # Fallback if mktemp is not available
        local temp_file="$SCRIPT_DIR/tmp/${prefix}.$$"
        touch "$temp_file"
        echo "$temp_file"
    fi
}

# Write an audit log entry
write_audit_log() {
    local service="$1"
    local env="$2"
    local action="$3"
    
    # Create the log directory if it doesn't exist
    mkdir -p "$(dirname "$AUDIT_LOG")"
    
    # Format the timestamp in ISO 8601 format
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Get the username
    local user="${USER:-$(whoami)}"
    
    # Create a JSON-like log entry
    local log_entry="{\"time\":\"$timestamp\",\"service\":\"$service\",\"env\":\"$env\",\"action\":\"$action\",\"by\":\"$user\"}"
    
    # Append to the log file
    echo "$log_entry" >> "$AUDIT_LOG"
}

# Get a key from the vault
get_key_from_vault() {
    local service="$1"
    local env="$2"
    local decrypted_file="$3"
    
    # The section name in the vault file
    local section="[$service:$env]"
    
    # Extract the key directly using grep with proper escaping
    local key_line=$(grep -A 10 "$section" "$decrypted_file" | grep "^key=" | head -n 1)
    
    if [ -z "$key_line" ]; then
        print_error "Key not found for service '$service' and environment '$env'"
        return 1
    fi
    
    # Extract just the key value
    echo "$key_line" | cut -d'=' -f2-
}

# Get all metadata for a key
get_key_metadata() {
    local service="$1"
    local env="$2"
    local decrypted_file="$3"
    
    # The section name in the vault file
    local section="[$service:$env]"
    
    # Extract metadata directly using grep
    local key=$(grep -A 10 "$section" "$decrypted_file" | grep "^key=" | head -n 1)
    local desc=$(grep -A 10 "$section" "$decrypted_file" | grep "^desc=" | head -n 1)
    local created=$(grep -A 10 "$section" "$decrypted_file" | grep "^created=" | head -n 1)
    local expires=$(grep -A 10 "$section" "$decrypted_file" | grep "^expires=" | head -n 1)
    local tags=$(grep -A 10 "$section" "$decrypted_file" | grep "^tags=" | head -n 1)
    
    if [ -z "$key" ]; then
        print_error "Key not found for service '$service' and environment '$env'"
        return 1
    fi
    
    # Output all metadata
    echo "$key"
    echo "$desc"
    echo "$created"
    echo "$expires"
    echo "$tags"
}

# Add or update a key in the vault
add_key_to_vault() {
    local service="$1"
    local env="$2"
    local key="$3"
    local desc="$4"
    local tags="$5"
    local decrypted_file="$6"
    
    # The section name in the vault file
    local section="[$service:$env]"
    
    # Check if the section already exists
    if grep -q "$section" "$decrypted_file"; then
        # Create a temporary file
        local temp_file=$(create_temp_file "vault_update")
        
        # Remove the existing section and add the new one
        awk -v section="$section" '
            BEGIN { skip=0; }
            $0 ~ "^"section"$" { skip=1; next; }
            skip && ($0 ~ /^\[.*\]$/ || $0 == "") { skip=0; }
            !skip { print; }
        ' "$decrypted_file" > "$temp_file"
        
        # Append the new section
        echo "$section" >> "$temp_file"
        echo "key=$key" >> "$temp_file"
        echo "desc=$desc" >> "$temp_file"
        echo "created=$(date -u +"%Y-%m-%d")" >> "$temp_file"
        echo "expires=" >> "$temp_file"
        echo "tags=$tags" >> "$temp_file"
        echo "" >> "$temp_file"
        
        # Replace the original file
        mv "$temp_file" "$decrypted_file"
    else
        # Append the new section
        echo "$section" >> "$decrypted_file"
        echo "key=$key" >> "$decrypted_file"
        echo "desc=$desc" >> "$decrypted_file"
        echo "created=$(date -u +"%Y-%m-%d")" >> "$decrypted_file"
        echo "expires=" >> "$decrypted_file"
        echo "tags=$tags" >> "$decrypted_file"
        echo "" >> "$decrypted_file"
    fi
}

# Delete a key from the vault
delete_key_from_vault() {
    local service="$1"
    local env="$2"
    local decrypted_file="$3"
    
    # The section name in the vault file
    local section="[$service:$env]"
    
    # Check if the section exists
    if ! grep -q "$section" "$decrypted_file"; then
        print_error "Key not found for service '$service' and environment '$env'"
        return 1
    fi
    
    # Create a temporary file
    local temp_file=$(create_temp_file "vault_delete")
    
    # Use awk to remove the section and its content
    awk -v section="$section" '
        BEGIN { skip=0; }
        $0 ~ "^"section"$" { skip=1; next; }
        skip && ($0 ~ /^\[.*\]$/ || $0 == "") { skip=0; }
        !skip { print; }
    ' "$decrypted_file" > "$temp_file"
    
    # Replace the original file
    mv "$temp_file" "$decrypted_file"
    
    return 0
}

# List all keys in the vault
list_keys_from_vault() {
    local decrypted_file="$1"
    local filter="$2"
    
    # Check if the vault file is empty
    if [ ! -s "$decrypted_file" ]; then
        print_info "Vault is empty. Add keys with 'keysmith.sh add'"
        return 0
    fi
    
    # Extract all section headers
    local sections=$(grep -E '^\[.*\]$' "$decrypted_file")
    
    if [ -z "$sections" ]; then
        print_info "No keys found in the vault."
        return 0
    fi
    
    # Print header
    printf "${CYAN}%-20s %-15s %-30s %-15s %-20s${RESET}\n" "SERVICE" "ENVIRONMENT" "DESCRIPTION" "CREATED" "TAGS"
    echo "--------------------------------------------------------------------------------------------------------"
    
    # Process each section
    while IFS= read -r section; do
        # Extract service and environment from section header [service:env]
        local service=$(echo "$section" | sed -E 's/^\[(.*):.*\]$/\1/')
        local env=$(echo "$section" | sed -E 's/^\[.*:(.*)\]$/\1/')
        
        # If a filter is provided, check if the service or env matches
        if [ -n "$filter" ] && [[ "$service" != *"$filter"* ]] && [[ "$env" != *"$filter"* ]]; then
            continue
        fi
        
        # Extract metadata directly using grep
        local desc=$(grep -A 10 "$section" "$decrypted_file" | grep "^desc=" | head -n 1 | cut -d'=' -f2-)
        local created=$(grep -A 10 "$section" "$decrypted_file" | grep "^created=" | head -n 1 | cut -d'=' -f2-)
        local tags=$(grep -A 10 "$section" "$decrypted_file" | grep "^tags=" | head -n 1 | cut -d'=' -f2-)
        
        # Print the key information
        printf "%-20s %-15s %-30s %-15s %-20s\n" "$service" "$env" "$desc" "$created" "$tags"
    done <<< "$sections"
}