# Runtime Scripts

Daily-use scripts for interacting with the AI agent system after setup is complete.

## Scripts Overview

| Script | Purpose | Example |
|--------|---------|---------|
| `send_task.py` | Send a task to the agent | `./send_task.py --project my-app --instruction "Add logging"` |

## Usage

`send_task.py` connects to Redis to communicate with the agent. Make sure Redis is running before using it:
```bash
cd /home/aiuser/local-ai-agent/docker && docker compose ps redis
```

The local web UI and REST API are exposed through the API gateway:
```bash
cd /home/aiuser/local-ai-agent/docker && docker compose ps api-gateway
```

Setup and recovery scripts now live under `setup/` on the VM host:
```bash
cd /home/aiuser/local-ai-agent/setup
./doctor.sh
```

### Sending a Task
```bash
./send_task.py --project my-web-app --instruction "Add error handling to the login function"
./send_task.py --project my-web-app --instruction "Add a health endpoint" --model qwen2.5-coder:1.5b --wait
```

The script will:
- Load repository configuration
- Validate the project exists
- Push the task to Redis queue
- Return a durable task ID
- Optionally poll Redis until the task finishes

### Web UI and REST API

Open the dashboard on your LAN:
```bash
http://<vm-ip>:8000
```

List projects:
```bash
curl http://<vm-ip>:8000/api/projects
```

Submit a task:
```bash
curl -X POST http://<vm-ip>:8000/api/tasks \
  -H 'Content-Type: application/json' \
  -d '{"project":"my-web-app","instruction":"Add request logging"}'
```

### Managing Repositories
Edit the repository list manually in:
```bash
/home/aiuser/local-ai-agent/settings/repos/repos.json
```

### Environment
These scripts expect:
- Redis running on localhost:6379 (default)
- Configuration at /home/aiuser/local-ai-agent/settings/repos/repos.json
- API gateway running on port 8000 for browser access
- You can override with environment variables:

```bash
export REDIS_URL=redis://localhost:6379
export CONFIG_REPO_PATH=/custom/path
```
