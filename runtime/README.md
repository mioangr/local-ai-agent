# Runtime

This folder contains the installed application files that are intended to be served or executed on the target server while the system is running.

It is the updater-managed application payload for the installation: code, scripts, updater assets, and web files that are placed in a known location and can be replaced with newer compatible versions.

As a rule, files stored here should be limited to assets that the live updater can safely update automatically by replacing them in place.

Current subfolders include:

- `agent/` for the worker process
- `api/` for the FastAPI gateway
- `cli/` for command-line entrypoints used after setup
- `shared/` for common Python helpers
- `updater/` for live-update logic and manifest
- `www/` for rendered web assets
