# API Gateway

This folder contains the FastAPI gateway for the local AI agent system.

Its purpose is to provide:

- the LAN web UI
- the REST API for task submission and task lookup
- the bridge between browser/API clients and the Redis-backed agent workflow

## Files and Subfolders

| Item | Purpose |
|------|---------|
| `main.py` | FastAPI application entrypoint. Defines routes for health checks, task submission, task lookup, and rendered pages. |
| `__init__.py` | Marks the folder as a Python package. |
| `routes/` | Reserved for route modules as the API grows. |
| `services/` | Small service helpers used by the API layer. |
| `templates/` | Legacy placeholder kept after moving rendered pages to `runtime/www/`. |

Read more in folder `runtime/api/services`.
Read more in folder `runtime/api/routes`.
