# Repository Configuration

This folder stores the repository definitions that the agent and API use when validating project names.

Its purpose is to keep the list of allowed repositories in one editable place outside the application code.

## Files

| File | Purpose |
|------|---------|
| `repos.json` | Defines the repositories the agent can access, along with each repository's default target branch. |
| `README.md` | Explains the structure and intended use of this folder. |

## `repos.json` Format

```json
{
  "repos": [
    {
      "name": "unique-project-name",
      "url": "https://github.com/username/repository",
      "branch": "main"
    }
  ]
}
```

## Fields

| Field | Required | Description |
|------|---------|---------|
| `name` | Yes | Short identifier used by the CLI and API, for example `--project my-app`. |
| `url` | Yes | Full GitHub repository URL. |
| `branch` | Yes | Default branch to target for pull requests. |

## Managing Repositories

Edit the JSON file directly:

```bash
nano /home/aiuser/local-ai-agent/settings/repos/repos.json
```

## Security Note

The GitHub token in `.env` must have access to every repository listed here.
