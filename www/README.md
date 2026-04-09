# Web Pages

This folder contains the rendered HTML pages served by the API gateway.

Its purpose is to keep the web-facing pages in a dedicated top-level folder instead of mixing them with Python modules.

## Files

| File | Purpose |
|------|---------|
| `index.html` | Main dashboard page for submitting tasks and viewing recent task activity. |
| `task_detail.html` | Detail page for a single queued or completed task. |
| `status.html` | Status page showing the shared activity log and a clear-log action. |

## Browser URLs

These pages are served by the API gateway on port `8000`.

| Page | Browser URL |
|------|-------------|
| `index.html` | `http://<vm-ip>:8000/` |
| `task_detail.html` | `http://<vm-ip>:8000/tasks/<task_id>` |
| `status.html` | `http://<vm-ip>:8000/status` |

Notes:

- Replace `<vm-ip>` with the IP address or hostname of the VM on your LAN
- `task_detail.html` is a dynamic page, so `<task_id>` must be replaced with a real task ID
