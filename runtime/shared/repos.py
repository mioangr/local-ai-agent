#!/usr/bin/env python3
"""Repository configuration helpers shared across services."""

import json
import os
from pathlib import Path
from typing import Dict, List

from runtime.shared.config import load_install_config


INSTALL_CONFIG = load_install_config()
AI_USER = INSTALL_CONFIG.get("AI_USER", "aiuser")
INSTALL_DEST_DIR = INSTALL_CONFIG.get("INSTALL_DEST_DIR", "local-ai-agent")
DEFAULT_CONFIG_PATH = Path(f"/home/{AI_USER}/{INSTALL_DEST_DIR}/settings/repos")
CONFIG_PATH = Path(
    os.getenv(
        "CONFIG_REPO_PATH",
        str(DEFAULT_CONFIG_PATH if DEFAULT_CONFIG_PATH.exists() else Path("/settings/repos")),
    )
)
CONFIG_FILE = CONFIG_PATH / "repos.json"


def load_repository_config() -> Dict:
    if not CONFIG_FILE.exists():
        return {"repos": []}

    with CONFIG_FILE.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def list_repositories() -> List[Dict[str, str]]:
    return load_repository_config().get("repos", [])


def get_repository_map() -> Dict[str, Dict[str, str]]:
    return {repo["name"]: repo for repo in list_repositories()}


def save_repository_config(config: Dict) -> None:
    """Save the complete repository configuration."""
    CONFIG_FILE.parent.mkdir(parents=True, exist_ok=True)
    with CONFIG_FILE.open("w", encoding="utf-8") as handle:
        json.dump(config, handle, indent=2)


def add_repository(name: str, url: str, branch: str = "main") -> Dict:
    """Add a new repository to the configuration."""
    config = load_repository_config()
    repos = config.get("repos", [])
    
    # Check for duplicate name
    for repo in repos:
        if repo.get("name") == name:
            raise ValueError(f"Repository '{name}' already exists")
    
    repos.append({
        "name": name,
        "url": url,
        "branch": branch
    })
    
    config["repos"] = repos
    save_repository_config(config)
    return {"name": name, "url": url, "branch": branch}


def update_repository(original_name: str, name: str, url: str, branch: str) -> Dict:
    """Update an existing repository."""
    config = load_repository_config()
    repos = config.get("repos", [])
    
    found = False
    for repo in repos:
        if repo.get("name") == original_name:
            repo["name"] = name
            repo["url"] = url
            repo["branch"] = branch
            found = True
            break
    
    if not found:
        raise ValueError(f"Repository '{original_name}' not found")
    
    # If name changed, check for duplicate
    if original_name != name:
        for repo in repos:
            if repo.get("name") == name and repo.get("name") != original_name:
                raise ValueError(f"Repository '{name}' already exists")
    
    config["repos"] = repos
    save_repository_config(config)
    return {"name": name, "url": url, "branch": branch}


def delete_repository(name: str) -> None:
    """Delete a repository from the configuration."""
    config = load_repository_config()
    repos = config.get("repos", [])
    
    original_count = len(repos)
    repos = [repo for repo in repos if repo.get("name") != name]
    
    if len(repos) == original_count:
        raise ValueError(f"Repository '{name}' not found")
    
    config["repos"] = repos
    save_repository_config(config)
