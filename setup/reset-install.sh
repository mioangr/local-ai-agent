#!/bin/bash
# Remove the installed project files and optionally the dedicated AI user.

SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

FORCE=0
REMOVE_USER=0
KEEP_VOLUMES=0

usage() {
    show_usage_header "$(basename "$0") [--force] [--remove-user] [--keep-volumes]"
    echo "Removes the local-ai-agent installation from $INSTALL_ROOT."
    echo ""
    echo "  --force         Skip confirmation prompts"
    echo "  --remove-user   Also delete the dedicated Linux user $AI_USER"
    echo "  --keep-volumes  Keep Docker volumes such as Ollama model data"
}

while [ $# -gt 0 ]; do
    case "$1" in
        --force)
            FORCE=1
            ;;
        --remove-user)
            REMOVE_USER=1
            ;;
        --keep-volumes)
            KEEP_VOLUMES=1
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            print_error "Unknown argument: $1"
            usage
            exit 1
            ;;
    esac
    shift
done

print_header "Remove Local AI Agent Installation"
echo "This will:"
echo "  - Stop and remove the project containers"
if [ "$KEEP_VOLUMES" -eq 0 ]; then
    echo "  - Remove project Docker volumes"
fi
echo "  - Delete $INSTALL_ROOT"
if [ "$REMOVE_USER" -eq 1 ]; then
    echo "  - Delete Linux user $AI_USER"
fi
echo ""

if [ "$FORCE" -ne 1 ]; then
    if ! confirm_action "Continue with install reset? (y/n) "; then
        echo "Aborted."
        exit 1
    fi
fi

require_sudo

print_step "Stopping Docker resources"
if [ -f "$COMPOSE_FILE" ]; then
    compose_args="down --remove-orphans"
    if [ "$KEEP_VOLUMES" -eq 0 ]; then
        compose_args="$compose_args -v"
    fi
    sudo bash -lc "cd '$DOCKER_DIR' && docker compose $compose_args" || true
else
    print_warning "Compose file not found at $COMPOSE_FILE; trying direct container removal"
fi

sudo docker rm -f ollama redis langgraph-agent >/dev/null 2>&1 || true

if [ -d "$INSTALL_ROOT" ]; then
    print_step "Removing install root $INSTALL_ROOT"
    sudo rm -rf "$INSTALL_ROOT"
else
    print_warning "Install root $INSTALL_ROOT does not exist"
fi

if [ "$REMOVE_USER" -eq 1 ]; then
    if id "$AI_USER" >/dev/null 2>&1; then
        print_step "Removing Linux user $AI_USER"
        sudo pkill -u "$AI_USER" >/dev/null 2>&1 || true
        sudo userdel -r "$AI_USER" >/dev/null 2>&1 || sudo userdel "$AI_USER"
    else
        print_warning "User $AI_USER does not exist"
    fi
fi

print_step "Install reset complete"
echo "You can rerun the installer after this cleanup."
