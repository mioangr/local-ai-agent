#!/bin/bash
# =============================================================================
# Script 06: Create Directory Structure
# =============================================================================
# Purpose: Creates all necessary directories for the AI agent
# Dependencies: User 'aiuser' exists
# Output: Complete folder structure under $INSTALL_ROOT
# =============================================================================

source "$(dirname "$0")/../common.sh"

print_header "Creating Directory Structure"

# List of directories to create
DIRECTORIES=(
    "$INSTALL_ROOT"
    "$DOCKER_DIR"
    "$RUNTIME_DIR"
    "$RUNTIME_AGENT_DIR"
    "$RUNTIME_API_DIR"
    "$RUNTIME_CLI_DIR"
    "$RUNTIME_SHARED_DIR"
    "$RUNTIME_UPDATER_DIR"
    "$RUNTIME_WWW_DIR"
    "$INSTALL_SETUP_DIR"
    "$REPOS_DIR"
    "$LOGS_DIR"
    "$WORKSPACE_DIR"
)

# Create directories
for dir in "${DIRECTORIES[@]}"; do
    print_step "Creating $dir"
    sudo mkdir -p "$dir"
    sudo chown -R $AI_USER:$AI_USER "$dir"
    sudo chmod 755 "$dir"
done

# Copy files from project to AI user's home
print_step "Copying project files to $INSTALL_ROOT..."

# Copy docker files
if [ -d "$PROJECT_ROOT/setup/docker" ]; then
    sudo cp -r "$PROJECT_ROOT/setup/docker/"* "$DOCKER_DIR/"
    sudo chown -R "$AI_USER:$AI_USER" "$DOCKER_DIR"
    echo "  ✓ Copied docker files"
fi

# Copy runtime files
if [ -d "$PROJECT_ROOT/runtime" ]; then
    sudo cp -r "$PROJECT_ROOT/runtime/"* "$RUNTIME_DIR/"
    sudo find "$RUNTIME_DIR" -type f -name "*.sh" -exec chmod +x {} \;
    sudo chown -R "$AI_USER:$AI_USER" "$RUNTIME_DIR"
    echo "  ✓ Copied runtime files"
fi

# Copy setup files
if [ -d "$PROJECT_ROOT/setup" ]; then
    sudo cp -r "$PROJECT_ROOT/setup/"* "$INSTALL_SETUP_DIR/"
    sudo chmod +x "$INSTALL_SETUP_DIR/"*.sh 2>/dev/null || true
    sudo chmod +x "$INSTALL_SETUP_DIR/components/"*.sh 2>/dev/null || true
    sudo chown -R "$AI_USER:$AI_USER" "$INSTALL_SETUP_DIR"
    echo "  ✓ Copied setup and recovery scripts"
fi

# Copy settings/repos template
if [ -d "$PROJECT_ROOT/settings/repos" ]; then
    sudo cp -r "$PROJECT_ROOT/settings/repos/"* "$REPOS_DIR/"
    sudo chown -R "$AI_USER:$AI_USER" "$REPOS_DIR"
    echo "  ✓ Copied repository configuration"
fi

if [ -f "$PROJECT_ROOT/install.conf" ]; then
    sudo cp "$PROJECT_ROOT/install.conf" "$INSTALL_ROOT/install.conf"
    sudo chown "$AI_USER:$AI_USER" "$INSTALL_ROOT/install.conf"
    echo "  ✓ Copied shared install configuration"
fi

echo ""
print_step "Directory structure created successfully"
echo ""
echo "Directory layout:"
echo "  $INSTALL_ROOT/"
echo "  ├── docker/          - Docker compose and container files"
echo "  ├── runtime/         - Updater-managed application files used while the system runs"
echo "  ├── setup/           - Setup and recovery scripts"
echo "  ├── settings/repos/  - Repository configurations"
echo "  ├── logs/            - Runtime logs"
echo "  ├── workspace/       - Temporary clones of repositories"
echo "  ├── install.conf     - Shared install configuration"
echo "  └── .env             - Secrets (created earlier)"
