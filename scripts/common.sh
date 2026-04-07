#!/bin/bash
# Shared helpers for host-side maintenance scripts.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
INSTALL_CONFIG_FILE="${INSTALL_CONFIG_FILE:-$ROOT_DIR/install.conf}"

AI_USER="aiuser"
INSTALL_DEST_DIR="local-ai-agent"
MODEL_NAME="qwen2.5-coder:1.5b"
LOG_LEVEL="INFO"

if [ -f "$INSTALL_CONFIG_FILE" ]; then
    # shellcheck disable=SC1090
    source "$INSTALL_CONFIG_FILE"
fi

if [ -f "$ROOT_DIR/docker/docker-compose.yml" ]; then
    INSTALL_ROOT="$ROOT_DIR"
else
    INSTALL_ROOT="/home/$AI_USER/$INSTALL_DEST_DIR"
fi

AI_HOME="/home/$AI_USER"
ENV_FILE="$INSTALL_ROOT/.env"
DOCKER_DIR="$INSTALL_ROOT/docker"
SCRIPTS_DIR="$INSTALL_ROOT/scripts"
SETTINGS_DIR="$INSTALL_ROOT/settings"
REPOS_DIR="$SETTINGS_DIR/repos"
LOGS_DIR="$INSTALL_ROOT/logs"
WORKSPACE_DIR="$INSTALL_ROOT/workspace"
COMPOSE_FILE="$DOCKER_DIR/docker-compose.yml"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo ""
    echo -e "${BLUE}===========================================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}===========================================================${NC}"
    echo ""
}

print_step() {
    echo -e "${GREEN}> $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}WARNING: $1${NC}"
}

print_error() {
    echo -e "${RED}ERROR: $1${NC}"
}

require_sudo() {
    print_step "Requesting sudo access..."
    sudo -v
}

confirm_action() {
    local prompt="$1"
    local reply

    if [ -t 0 ]; then
        read -p "$prompt" -n 1 -r reply
    elif [ -r /dev/tty ]; then
        read -p "$prompt" -n 1 -r reply < /dev/tty
    else
        print_error "Confirmation required, but no terminal is attached"
        exit 1
    fi
    echo

    [[ "$reply" =~ ^[Yy]$ ]]
}

sudo_available_noninteractive() {
    if [ "$(id -u)" -eq 0 ]; then
        return 0
    fi

    sudo -n true >/dev/null 2>&1
}

show_usage_header() {
    echo "Usage: $1"
    echo ""
}
