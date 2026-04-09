# Shared Python Helpers

This folder contains Python modules shared across the agent, CLI tools, and API gateway.

Its purpose is to keep common configuration, repository access, task state handling, and logging logic in one place instead of duplicating it in multiple entrypoints.

## Files

| File | Purpose |
|------|---------|
| `__init__.py` | Marks the folder as a Python package. |
| `config.py` | Shared access to repo-root configuration such as `install.conf` and project paths. |
| `logging_utils.py` | Shared helpers for the common activity log. |
| `repos.py` | Shared helpers for loading repository definitions. |
| `tasks.py` | Shared Redis-backed task creation, storage, status updates, and listing logic. |
