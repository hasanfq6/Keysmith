#!/usr/bin/env bash
# keysmith.sh - A terminal-only, secure API key vault
# No Python. No dependencies. No mercy.

set -e

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source utility scripts
source "$SCRIPT_DIR/utils/print.sh"
source "$SCRIPT_DIR/utils/crypto.sh"
source "$SCRIPT_DIR/utils/vault.sh"

# Default config values
export ENCRYPTION_METHOD="openssl"
export VAULT_FILE="$SCRIPT_DIR/vault/vault.enc"
export AUDIT_LOG="$SCRIPT_DIR/vault/audit.log"
export EDITOR="nano"
export DISPLAY_TIME=5

# Load config if exists
CONFIG_FILE="$SCRIPT_DIR/config/keysmith.conf"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
    # Re-export variables from config
    export ENCRYPTION_METHOD
    export VAULT_FILE
    export AUDIT_LOG
    export EDITOR
    export DISPLAY_TIME
fi

# Create directories if they don't exist
mkdir -p "$SCRIPT_DIR/vault" "$SCRIPT_DIR/tmp" "$SCRIPT_DIR/config"

# Main function
main() {
    # Check if a command was provided
    if [ $# -eq 0 ]; then
        print_error "No command specified."
        print_usage
        exit 1
    fi

    # Parse command
    COMMAND="$1"
    shift

    # Execute the appropriate command script
    case "$COMMAND" in
        init)
            "$SCRIPT_DIR/bin/init.sh" "$@"
            ;;
        add)
            "$SCRIPT_DIR/bin/add.sh" "$@"
            ;;
        get)
            "$SCRIPT_DIR/bin/get.sh" "$@"
            ;;
        list)
            "$SCRIPT_DIR/bin/list.sh" "$@"
            ;;
        delete)
            "$SCRIPT_DIR/bin/delete.sh" "$@"
            ;;
        edit)
            "$SCRIPT_DIR/bin/edit.sh" "$@"
            ;;
        lock)
            "$SCRIPT_DIR/bin/lock.sh" "$@"
            ;;
        help)
            print_usage
            ;;
        *)
            print_error "Unknown command: $COMMAND"
            print_usage
            exit 1
            ;;
    esac
}

# Print usage information
print_usage() {
    cat << EOF
keysmith.sh - A terminal-only, secure API key vault

Usage:
  ./keysmith.sh COMMAND [OPTIONS]

Commands:
  init                Initialize the vault
  add                 Add a new API key
  get                 Retrieve an API key
  list                List all stored keys
  delete              Delete an API key
  edit                Edit an existing key
  lock                Lock the vault
  help                Show this help message

Examples:
  ./keysmith.sh init
  ./keysmith.sh add --service openai --env prod
  ./keysmith.sh get --service openai --env prod
  ./keysmith.sh list
  ./keysmith.sh delete --service openai --env prod

For more information, see the README.md file.
EOF
}

# Run the main function
main "$@"