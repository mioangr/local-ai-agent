#!/usr/bin/env python3
"""Repository configuration helpers shared across services."""

import json
import os
from pathlib import Path
from typing import Dict, List

from shared.config import load_install_config


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

