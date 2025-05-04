# Keysmith

A terminal-only, secure API key vault written in portable Bash.

No Python. No dependencies. No mercy.

## Features

- Securely store and retrieve API keys locally
- Use GPG for encryption (or fallback to OpenSSL AES)
- Show key for 5 seconds, then erase it from the terminal
- Write audit logs for all key fetches
- Works on Termux, Linux, macOS
- Full CLI interface — keysmith.sh get, add, list, etc.

## Installation

Clone the repository and make the script executable:

```bash
git clone https://github.com/HasanFq/Keysmith.git
cd Keysmith
chmod +x keysmith.sh
```

Or use the install script:

```bash
./install.sh
```

## Usage

### Initialize the Vault

```bash
./keysmith.sh init
```

### Add a New API Key

```bash
./keysmith.sh add --service openai --env prod
```

### Retrieve an API Key

```bash
./keysmith.sh get --service openai --env prod
```

### List All Keys

```bash
./keysmith.sh list
```

### Delete a Key

```bash
./keysmith.sh delete --service openai --env prod
```

### Edit a Key

```bash
./keysmith.sh edit --service openai --env prod
```

### Lock the Vault

```bash
./keysmith.sh lock
```

## Security Features

- GPG or OpenSSL encryption
- All decrypted data lives in temp only during access
- Key display is time-limited, auto-erased
- Audit trail is always on
- Optional: shred temp files with shred if installed

## Vault Format

Stored as a simple .ini-style key-value list:

```ini
[openai:prod]
key=sk-xxx
desc=GPT-4 prod key
created=2025-05-01
expires=
tags=gpt,nlp
```

## Audit Log Format

Logged to vault/audit.log as plaintext JSON lines:

```json
{"time":"2025-05-01T21:50Z","service":"openai","env":"prod","action":"get","by":"$USER"}
```

## Configuration

File: config/keysmith.conf

Example:

```bash
ENCRYPTION_METHOD="gpg" # Or Openssl
VAULT_FILE="vault/vault.enc"
EDITOR="nano"
DISPLAY_TIME=5
```

## Requirements

- Bash
- GPG (recommended) or OpenSSL
- Basic Unix utilities (grep, awk, sed, etc.)

## License

MIT
