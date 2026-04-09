#!/bin/bash
# Reset runtime state while keeping the installed files and user account.

SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

FORCE=0
PURGE_VOLUMES=0
KEEP_WORKSPACE=0
KEEP_LOGS=0

usage() {
    show_usage_header "$(basename "$0") [--force] [--purge-volumes] [--keep-workspace] [--keep-logs]"
    echo "Resets the running containers and clears transient project state."
    echo ""
    echo "  --force           Skip confirmation prompts"
    echo "  --purge-volumes   Also remove Docker volumes managed by docker compose"
    echo "  --keep-workspace  Do not clear $WORKSPACE_DIR"
    echo "  --keep-logs       Do not clear $LOGS_DIR"
}

while [ $# -gt 0 ]; do
    case "$1" in
        --force)
            FORCE=1
            ;;
        --purge-volumes)
            PURGE_VOLUMES=1
            ;;
        --keep-workspace)
            KEEP_WORKSPACE=1
            ;;
        --keep-logs)
            KEEP_LOGS=1
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

print_header "Reset Local AI Agent Runtime"
echo "This will:"
echo "  - Stop and remove the project containers"
echo "  - Remove orphaned compose resources"
if [ "$PURGE_VOLUMES" -eq 1 ]; then
    echo "  - Remove Docker volumes for Ollama and Redis"
fi
if [ "$KEEP_WORKSPACE" -eq 0 ]; then
    echo "  - Clear workspace contents in $WORKSPACE_DIR"
fi
if [ "$KEEP_LOGS" -eq 0 ]; then
    echo "  - Clear logs in $LOGS_DIR"
fi
echo ""

if [ "$FORCE" -ne 1 ]; then
    if ! confirm_action "Continue with runtime reset? (y/n) "; then
        echo "Aborted."
        exit 1
    fi
fi

require_sudo

print_step "Stopping Docker Compose services"
if [ -f "$COMPOSE_FILE" ]; then
    compose_args="down --remove-orphans"
    if [ "$PURGE_VOLUMES" -eq 1 ]; then
        compose_args="$compose_args -v"
    fi
    sudo bash -lc "cd '$DOCKER_DIR' && docker compose $compose_args" || true
else
    print_warning "Compose file not found at $COMPOSE_FILE; falling back to container cleanup"
fi

print_step "Removing known project containers if they still exist"
sudo docker rm -f ollama redis langgraph-agent api-gateway >/dev/null 2>&1 || true

if [ "$KEEP_WORKSPACE" -eq 0 ]; then
    print_step "Clearing workspace contents"
    sudo mkdir -p "$WORKSPACE_DIR"
    sudo find "$WORKSPACE_DIR" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
    sudo chown -R "$AI_USER:$AI_USER" "$WORKSPACE_DIR" 2>/dev/null || true
fi

if [ "$KEEP_LOGS" -eq 0 ]; then
    print_step "Clearing logs"
    sudo mkdir -p "$LOGS_DIR"
    sudo find "$LOGS_DIR" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
    sudo chown -R "$AI_USER:$AI_USER" "$LOGS_DIR" 2>/dev/null || true
fi

print_step "Runtime reset complete"
echo "Next recommended step: $INSTALL_SETUP_DIR/doctor.sh"
