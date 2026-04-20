# Setup

This folder contains the main installation, bootstrap, recovery, and diagnostic scripts for the project.

Its purpose is to install the stack, verify it, and help recover from partial or failed installs.

## Files and Subfolders

| Item | Purpose |
|------|---------|
| `setup.sh` | Main umbrella installer that runs the one-time setup sequence. |
| `install-from-web.sh` | Bootstrap script meant to be executed directly from a URL. |
| `common.sh` | Shared shell helpers and shared path/config variables for setup scripts. |
| `doctor.sh` | Diagnostic script that checks the install and runtime state. |
| `reset-install.sh` | Removes the installed environment, optionally preserving volumes or removing the dedicated user. |
| `reset-runtime.sh` | Clears transient runtime state while keeping the installed files. |
| `components/` | Individual one-time install step scripts. |
| `docker/` | Docker build and compose assets used by the setup flow. |

Read more in folder `setup/components`.
Read more in folder `setup/docker`.

## Web Updater Password

The browser-based live updater uses a dedicated secret stored in the installation `.env` file:

```bash
UPDATE_UI_PASSWORD=choose-a-strong-password
```

This password is only for approving browser-triggered live updates. It should be different from the Linux login password for `aiuser`.

If you add or rotate this password later, restart only the API service so the web UI picks up the new value:

```bash
cd /home/aiuser/local-ai-agent/docker
docker compose up -d --force-recreate api-gateway
```
