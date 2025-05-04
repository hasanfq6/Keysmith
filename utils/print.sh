#!/usr/bin/env bash
# print.sh - Terminal output utilities for keysmith

# Colors
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
MAGENTA="\033[0;35m"
CYAN="\033[0;36m"
RESET="\033[0m"

# Print functions
print_info() {
    echo -e "${BLUE}[INFO]${RESET} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${RESET} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${RESET} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${RESET} $1" >&2
}

print_debug() {
    if [ "${DEBUG:-0}" -eq 1 ]; then
        echo -e "${MAGENTA}[DEBUG]${RESET} $1" >&2
    fi
}

# Terminal control functions
hide_cursor() {
    tput civis 2>/dev/null || echo -ne "\033[?25l"
}

show_cursor() {
    tput cnorm 2>/dev/null || echo -ne "\033[?25h"
}

erase_line() {
    tput cuu1 2>/dev/null && tput el 2>/dev/null || echo -ne "\033[1A\033[2K"
}

# Display a key for a limited time, then erase it
display_key_timed() {
    local key="$1"
    local display_time="${2:-5}"
    
    # Hide cursor
    hide_cursor
    
    # Display the key
    echo -e "${CYAN}Key:${RESET} $key"
    
    # Wait for the specified time
    sleep "$display_time"
    
    # Erase the line with the key
    erase_line
    
    # Show cursor again
    show_cursor
    
    # Print a message indicating the key was displayed
    print_info "Key was displayed for $display_time seconds and erased."
}

# Trap to ensure cursor is restored on exit
trap show_cursor EXIT INT TERM