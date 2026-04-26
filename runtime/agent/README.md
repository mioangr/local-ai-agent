# AI Agent

This folder contains the core worker code that processes queued tasks and interacts with GitHub repositories.

Its purpose is to receive instructions from Redis, apply the LangGraph workflow, make repository changes, and publish task results.

## Files

| File | Purpose |
|------|---------|
| `langgraph_agent.py` | Main worker process. Connects to Redis, talks to Ollama and GitHub, updates task state, writes shared logs, and runs the LangGraph flow. |
| `repo_manager.py` | Legacy utility for managing repository definitions (superseded by web UI at `/repos`). |
| `README.md` | Folder-local documentation for the agent worker. |

## Runtime Notes

- The agent consumes tasks from Redis queue `task:queue`
- The agent looks up repositories from `settings/repos/repos.json` (manage via web UI at `/repos`)
- The agent writes runtime messages to the shared activity log
- The agent normally runs inside Docker, but the main script can also be launched manually for testing
