#!/bin/bash
# =============================================================================
# Script 05: Configure Secrets
# =============================================================================
# Purpose: Prompts for GitHub token and stores it securely in .env file
# Dependencies: User 'aiuser' exists
# Output: $INSTALL_ROOT/.env with GitHub and runtime settings
# =============================================================================

source "$(dirname "$0")/common.sh"

print_header "Configuring Secrets"

get_env_value() {
    local key="$1"

    if [ ! -f "$ENV_FILE" ]; then
        return 1
    fi

    grep -E "^${key}=" "$ENV_FILE" | tail -n 1 | cut -d= -f2-
}

mask_token() {
    local token="$1"
    local token_length=${#token}

    if [ "$token_length" -le 8 ]; then
        printf '%s\n' "[saved]"
        return 0
    fi

    printf '%s\n' "${token:0:4}...${token: -4}"
}

EXISTING_GITHUB_TOKEN="$(get_env_value "GITHUB_TOKEN")"
EXISTING_GITHUB_USERNAME="$(get_env_value "GITHUB_USERNAME")"
GITHUB_TOKEN="$EXISTING_GITHUB_TOKEN"
GITHUB_USERNAME="$EXISTING_GITHUB_USERNAME"

NEEDS_GITHUB_TOKEN_PROMPT=true
NEEDS_GITHUB_USERNAME_PROMPT=true

if [ -n "$EXISTING_GITHUB_TOKEN" ]; then
    print_warning ".env file already contains a GitHub token: $(mask_token "$EXISTING_GITHUB_TOKEN")"
    prompt_yes_no "Set the GitHub token again? (y/n) " REPLY
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        NEEDS_GITHUB_TOKEN_PROMPT=false
        print_step "Keeping the existing GitHub token"
    fi
fi

if [ -n "$EXISTING_GITHUB_USERNAME" ]; then
    print_warning ".env file already contains a GitHub username: $EXISTING_GITHUB_USERNAME"
    prompt_yes_no "Set the GitHub username again? (y/n) " REPLY
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        NEEDS_GITHUB_USERNAME_PROMPT=false
        print_step "Keeping the existing GitHub username"
    fi
fi

if [ "$NEEDS_GITHUB_TOKEN_PROMPT" = true ]; then
    echo ""
    echo "To interact with GitHub, you need a Personal Access Token (PAT)."
    echo ""
    echo "Create a token here: https://github.com/settings/tokens"
    echo ""
    echo "Required permissions:"
    echo "  - repo (full control of private repositories)"
    echo "  - workflow (if using GitHub Actions)"
    echo "  - write:discussion (optional, for comments)"
    echo ""
    prompt_enter "Press Enter when you have your token ready..."
fi

if [ "$NEEDS_GITHUB_TOKEN_PROMPT" = true ]; then
    echo ""
    prompt_input "Enter your GitHub token (visible): " GITHUB_TOKEN
fi

if [ "$NEEDS_GITHUB_USERNAME_PROMPT" = true ]; then
    prompt_input "Enter your GitHub username: " GITHUB_USERNAME
fi

# Validate token (basic check)
if [ -z "$GITHUB_TOKEN" ] || [ -z "$GITHUB_USERNAME" ]; then
    die 1 "Token and username are required" "Run this script again and provide both values"
fi

# Create .env file
print_step "Creating .env file at $ENV_FILE..."
sudo mkdir -p "$INSTALL_ROOT"
sudo chown "$AI_USER:$AI_USER" "$INSTALL_ROOT"

sudo tee "$ENV_FILE" > /dev/null << EOF
# GitHub Authentication
GITHUB_TOKEN=$GITHUB_TOKEN
GITHUB_USERNAME=$GITHUB_USERNAME

# LLM Configuration
OLLAMA_URL=http://ollama:11434
MODEL_NAME=$MODEL_NAME

# Runtime Configuration
REDIS_URL=redis://redis:6379
WORKSPACE=/workspace
LOG_LEVEL=$LOG_LEVEL
EOF

# Set secure permissions
sudo chmod 600 "$ENV_FILE"
sudo chown $AI_USER:$AI_USER "$ENV_FILE"

echo ""
print_step "Secrets configured successfully"
echo "✓ Token stored securely in $ENV_FILE"
echo "✓ Permissions set to 600 (readable only by $AI_USER)"
