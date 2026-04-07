#!/bin/bash
# =============================================================================
# Script 07: Setup Docker Compose
# =============================================================================
# Purpose: Builds and starts Docker containers for Ollama, Agent, and Redis
# Dependencies: Docker installed, .env file exists
# Output: Running containers: ollama, langgraph-agent, redis
# =============================================================================

source "$(dirname "$0")/common.sh"

print_header "Setting Up Docker Containers"

run_compose_as_aiuser() {
    local compose_cmd="$1"

    sudo -iu "$AI_USER" bash -lc "
        cd '$DOCKER_DIR'
        docker compose $compose_cmd
    "
}

# Check if compose file exists
if [ ! -f "$COMPOSE_FILE" ]; then
    die 1 "docker-compose.yml not found at $COMPOSE_FILE" \
           "Make sure the docker folder was copied correctly in script 06"
fi

# Switch to ai user context for Docker operations
print_step "Building Docker images (this may take a few minutes)..."
run_compose_as_aiuser "build"
check_error "Docker build failed"

print_step "Starting containers..."
run_compose_as_aiuser "up -d"
check_error "Failed to start containers"

# Wait for containers to be ready
print_step "Waiting for containers to be ready..."
sleep 5

# Check container status
print_step "Verifying container status..."

CONTAINERS=("ollama" "langgraph-agent" "redis")
FAILED_CONTAINERS=()
for container in "${CONTAINERS[@]}"; do
    if sudo docker ps --format 'table {{.Names}}' | grep -q "^$container$"; then
        STATUS=$(sudo docker ps --filter "name=$container" --format "{{.Status}}")
        echo "  ✓ $container - $STATUS"
    else
        print_warning "$container container is not running"
        echo "  Check logs: sudo docker logs $container"
        FAILED_CONTAINERS+=("$container")
    fi
done

if [ ${#FAILED_CONTAINERS[@]} -gt 0 ]; then
    echo ""
    echo "Run this to inspect container logs:"
    echo "  cd $DOCKER_DIR && docker compose logs --no-color ${FAILED_CONTAINERS[*]}"
    echo ""
    die 1 "One or more containers failed to start: ${FAILED_CONTAINERS[*]}" \
           "Review the docker compose output above, then run: cd $DOCKER_DIR && docker compose logs"
fi

echo ""
print_step "Docker containers started successfully"
echo ""
echo "Useful commands:"
echo "  cd $DOCKER_DIR && docker compose logs -f"
echo "  cd $DOCKER_DIR && docker compose ps"
echo "  cd $DOCKER_DIR && docker compose down"
