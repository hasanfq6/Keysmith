#!/usr/bin/env bash
# test_all_commands.sh - Test all keysmith commands

# Set up test environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Source utilities
source "$SCRIPT_DIR/utils/print.sh"

# Test password
TEST_PASSWORD="password123"

# Function to run a command with the test password
run_with_password() {
    local cmd="$1"
    echo "$TEST_PASSWORD" | ./keysmith.sh $cmd
}

# Function to test a command
test_command() {
    local cmd="$1"
    local description="$2"
    
    echo "===== Testing: $description ====="
    ./keysmith.sh $cmd
    if [ $? -eq 0 ]; then
        echo "✅ PASSED: $description"
    else
        echo "❌ FAILED: $description"
    fi
    echo
}

# Function to test a command that requires password input
test_command_with_password() {
    local cmd="$1"
    local description="$2"
    
    echo "===== Testing: $description ====="
    echo "$TEST_PASSWORD" | ./keysmith.sh $cmd
    if [ $? -eq 0 ]; then
        echo "✅ PASSED: $description"
    else
        echo "❌ FAILED: $description"
    fi
    echo
}

# Start testing
echo "Starting keysmith command tests..."
echo "Using test password: $TEST_PASSWORD"
echo

# Test help command
test_command "help" "Help command"

# Test lock command
test_command "lock" "Lock command"

# Test list command
test_command_with_password "list" "List command"

# Test get command for OpenAI key
test_command_with_password "get --service openai --env prod" "Get OpenAI key"

# Test get command with metadata
test_command_with_password "get --service openai --env prod --metadata" "Get OpenAI key with metadata"

# Test get command for GitHub key
test_command_with_password "get --service github --env personal" "Get GitHub key"

# Test delete command
echo "===== Testing: Delete command ====="
echo "$TEST_PASSWORD" | ./keysmith.sh delete --service github --env personal
if [ $? -eq 0 ]; then
    echo "✅ PASSED: Delete command"
else
    echo "❌ FAILED: Delete command"
fi
echo

# Test add command
echo "===== Testing: Add command ====="
# Use expect-like approach to handle interactive prompts
(echo "$TEST_PASSWORD"; sleep 1; echo "ghp_123456789abcdef"; sleep 1; echo "GitHub personal access token"; sleep 1; echo ""; sleep 1; echo "github,api"; sleep 1; echo "y") | ./keysmith.sh add --service github --env personal
if [ $? -eq 0 ]; then
    echo "✅ PASSED: Add command"
else
    echo "❌ FAILED: Add command"
fi
echo

# Verify the vault content
echo "===== Verifying vault content ====="
echo "$TEST_PASSWORD" | ./debug_vault.sh
echo

echo "All tests completed!"