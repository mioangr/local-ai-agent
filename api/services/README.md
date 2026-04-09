# API Services

This folder contains helper modules used by the FastAPI gateway.

The service layer keeps small pieces of logic out of the HTTP handlers so the API stays easier to read and maintain.

## Files

| File | Purpose |
|------|---------|
| `__init__.py` | Marks the folder as a Python package. |
| `redis_client.py` | Creates the Redis client used by the API layer. |
| `repositories.py` | Provides access to configured projects from `settings/repos/repos.json`. |
| `tasks.py` | Wraps task creation, submission, listing, and lookup for the API. |
