#!/bin/bash
# =============================================================================
# Script 05: Configure Secrets
# =============================================================================
# Purpose: Prompts for GitHub token and stores it securely in .env file
# Dependencies: User 'aiuser' exists
# Output: $INSTALL_ROOT/.env with GitHub and runtime settings
# =============================================================================

source "$(dirname "$0")/../common.sh"

print_header "Configuring Secrets"

mask_token() {
    local token="$1"
    local token_length=${#token}

    if [ "$token_length" -le 8 ]; then
        printf '%s\n' "[saved]"
        return 0
    fi

    printf '%s\n' "${token:0:4}...${token: -4}"
}

EXISTING_GITHUB_TOKEN="$(get_saved_env_value "GITHUB_TOKEN" || true)"
EXISTING_GITHUB_USERNAME="$(get_saved_env_value "GITHUB_USERNAME" || true)"
EXISTING_AIUSER_PASSWORD="$(get_saved_env_value "AIUSER_PASSWORD" || true)"
EXISTING_UPDATE_UI_PASSWORD="$(get_saved_env_value "UPDATE_UI_PASSWORD" || true)"
GITHUB_TOKEN="$EXISTING_GITHUB_TOKEN"
GITHUB_USERNAME="$EXISTING_GITHUB_USERNAME"
AIUSER_PASSWORD="$EXISTING_AIUSER_PASSWORD"
UPDATE_UI_PASSWORD="$EXISTING_UPDATE_UI_PASSWORD"

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

if [ -n "$EXISTING_AIUSER_PASSWORD" ]; then
    print_step "A saved login password for $AI_USER was found in the existing secrets."
fi

if [ -n "$EXISTING_UPDATE_UI_PASSWORD" ]; then
    print_step "A saved web update password was found and will be kept unless you change it now."
    prompt_yes_no "Set the web update password again? (y/n) " REPLY
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        UPDATE_UI_PASSWORD=""
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

if [ -z "$UPDATE_UI_PASSWORD" ]; then
    echo ""
    echo "The web updater can be protected with a dedicated password."
    echo "This password is only for approving browser-triggered live updates."
    echo "It should be different from your Linux user password."
    prompt_secret "Enter the web update password: " UPDATE_UI_PASSWORD
fi

# Validate token (basic check)
if [ -z "$GITHUB_TOKEN" ] || [ -z "$GITHUB_USERNAME" ] || [ -z "$UPDATE_UI_PASSWORD" ]; then
    die 1 "Token, username, and web update password are required" "Run this script again and provide all values"
fi

# Create .env file
print_step "Creating .env file at $ENV_FILE..."
sudo mkdir -p "$INSTALL_ROOT"
sudo chown "$AI_USER:$AI_USER" "$INSTALL_ROOT"

sudo tee "$ENV_FILE" > /dev/null << EOF
# GitHub Authentication
GITHUB_TOKEN=$GITHUB_TOKEN
GITHUB_USERNAME=$GITHUB_USERNAME

# Local Linux User
AIUSER_PASSWORD=$AIUSER_PASSWORD
UPDATE_UI_PASSWORD=$UPDATE_UI_PASSWORD

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
echo "✓ Saved login password state for $AI_USER stored in $ENV_FILE"
echo "✓ Web update password stored in $ENV_FILE"
echo "✓ Permissions set to 600 (readable only by $AI_USER)"
