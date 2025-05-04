#!/usr/bin/env bash
# lock.sh - Lock the vault (clear any cached sessions)

# Source the parent script to get access to utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/utils/print.sh"
source "$SCRIPT_DIR/utils/crypto.sh"
source "$SCRIPT_DIR/utils/vault.sh"

# Clear all session files
print_info "Locking vault..."

# Find and remove all session files
session_files=$(find "$SCRIPT_DIR/tmp" -name ".session_*" 2>/dev/null)

if [ -n "$session_files" ]; then
    for file in $session_files; do
        secure_delete "$file"
    done
    print_success "Vault locked. All sessions cleared."
else
    print_info "No active sessions found. Vault is already locked."
fi

# Write to audit log
write_audit_log "system" "lock" "lock"