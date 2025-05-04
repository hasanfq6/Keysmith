#!/usr/bin/env bash
# crypto.sh - Encryption utilities for keysmith

# Check for GPG or OpenSSL availability
check_encryption_tools() {
    if command -v gpg >/dev/null 2>&1; then
        print_debug "GPG found, using as primary encryption method"
        ENCRYPTION_METHOD="gpg"
        return 0
    elif command -v openssl >/dev/null 2>&1; then
        print_debug "OpenSSL found, using as fallback encryption method"
        ENCRYPTION_METHOD="openssl"
        return 0
    else
        print_error "Neither GPG nor OpenSSL found. Cannot proceed with encryption."
        return 1
    fi
}

# Encrypt a file using the configured method
encrypt_file() {
    local input_file="$1"
    local output_file="$2"
    local password="$3"
    
    # Ensure the output directory exists
    mkdir -p "$(dirname "$output_file")"
    
    case "$ENCRYPTION_METHOD" in
        gpg)
            if [ -z "$password" ]; then
                # Interactive mode
                gpg --batch --yes --symmetric --cipher-algo AES256 --output "$output_file" "$input_file" 2>/dev/null
            else
                # Non-interactive mode (with password)
                echo "$password" | gpg --batch --yes --passphrase-fd 0 --symmetric --cipher-algo AES256 --output "$output_file" "$input_file" 2>/dev/null
            fi
            ;;
        openssl)
            if [ -z "$password" ]; then
                # Interactive mode
                echo "Running: openssl enc -aes-256-cbc -salt -pbkdf2 -in $input_file -out $output_file" >&2
                openssl enc -aes-256-cbc -salt -pbkdf2 -in "$input_file" -out "$output_file"
            else
                # Non-interactive mode (with password)
                echo "Running: echo \$password | openssl enc -aes-256-cbc -salt -pbkdf2 -in $input_file -out $output_file -pass stdin" >&2
                echo "$password" | openssl enc -aes-256-cbc -salt -pbkdf2 -in "$input_file" -out "$output_file" -pass stdin
            fi
            ;;
        *)
            print_error "Unknown encryption method: $ENCRYPTION_METHOD"
            return 1
            ;;
    esac
    
    # Check if encryption was successful
    if [ $? -eq 0 ]; then
        return 0
    else
        print_error "Encryption failed."
        return 1
    fi
}

# Decrypt a file using the configured method
decrypt_file() {
    local input_file="$1"
    local output_file="$2"
    local password="$3"
    
    # Check if the input file exists
    if [ ! -f "$input_file" ]; then
        print_error "Encrypted file not found: $input_file"
        return 1
    fi
    
    case "$ENCRYPTION_METHOD" in
        gpg)
            if [ -z "$password" ]; then
                # Interactive mode
                gpg --decrypt --output "$output_file" "$input_file" 2>/dev/null
            else
                # Non-interactive mode (with password)
                echo "$password" | gpg --batch --yes --passphrase-fd 0 --decrypt --output "$output_file" "$input_file" 2>/dev/null
            fi
            ;;
        openssl)
            if [ -z "$password" ]; then
                # Interactive mode
                openssl enc -d -aes-256-cbc -pbkdf2 -in "$input_file" -out "$output_file"
            else
                # Non-interactive mode (with password)
                echo "$password" | openssl enc -d -aes-256-cbc -pbkdf2 -in "$input_file" -out "$output_file" -pass stdin
            fi
            ;;
        *)
            print_error "Unknown encryption method: $ENCRYPTION_METHOD"
            return 1
            ;;
    esac
    
    # Check if decryption was successful
    if [ $? -eq 0 ]; then
        return 0
    else
        print_error "Decryption failed. Incorrect password?"
        return 1
    fi
}

# Securely delete a file if possible
secure_delete() {
    local file="$1"
    
    if [ ! -f "$file" ]; then
        return 0
    fi
    
    if command -v shred >/dev/null 2>&1; then
        shred -u "$file"
    else
        # Fallback if shred is not available
        rm -f "$file"
    fi
}

# Initialize a session key (for caching the master password)
init_session() {
    # Generate a random session ID
    SESSION_ID=$(date +%s%N | sha256sum | head -c 16)
    
    # Create a session file
    SESSION_FILE="$SCRIPT_DIR/tmp/.session_$SESSION_ID"
    touch "$SESSION_FILE"
    
    # Set permissions
    chmod 600 "$SESSION_FILE"
    
    echo "$SESSION_ID"
}

# Store the master password in the session
store_session_password() {
    local session_id="$1"
    local password="$2"
    
    SESSION_FILE="$SCRIPT_DIR/tmp/.session_$session_id"
    
    # Encrypt the password with a simple XOR with the session ID
    # This is not highly secure but better than plaintext
    local encrypted=""
    for (( i=0; i<${#password}; i++ )); do
        local char="${password:$i:1}"
        local key_char="${session_id:$(($i % ${#session_id})):1}"
        printf -v encrypted_char '\\%03o' "$(( $(printf '%d' "'$char") ^ $(printf '%d' "'$key_char") ))"
        encrypted+="$encrypted_char"
    done
    
    echo -e "$encrypted" > "$SESSION_FILE"
}

# Get the master password from the session
get_session_password() {
    local session_id="$1"
    
    SESSION_FILE="$SCRIPT_DIR/tmp/.session_$session_id"
    
    if [ ! -f "$SESSION_FILE" ]; then
        return 1
    fi
    
    # Read the encrypted password
    local encrypted=$(cat "$SESSION_FILE")
    
    # Decrypt the password
    local password=""
    local i=0
    while [ $i -lt ${#encrypted} ]; do
        if [[ "${encrypted:$i:1}" == "\\" ]]; then
            local octal="${encrypted:$i+1:3}"
            local char=$(printf "\\$octal")
            local key_char="${session_id:$(($i/4 % ${#session_id})):1}"
            printf -v decrypted_char '%b' "\\$(printf '%03o' "$(( $(printf '%d' "'$char") ^ $(printf '%d' "'$key_char") ))")"
            password+="$decrypted_char"
            i=$((i+4))
        else
            i=$((i+1))
        fi
    done
    
    echo "$password"
}

# Clear the session
clear_session() {
    local session_id="$1"
    
    SESSION_FILE="$SCRIPT_DIR/tmp/.session_$session_id"
    
    if [ -f "$SESSION_FILE" ]; then
        secure_delete "$SESSION_FILE"
    fi
}