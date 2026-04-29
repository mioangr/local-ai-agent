#!/usr/bin/env python3
"""Helpers for talking to the local Ollama service."""

from __future__ import annotations

import os
from typing import Any, Dict, List

import requests


OLLAMA_URL = os.getenv("OLLAMA_URL", "http://ollama:11434")
REQUEST_TIMEOUT_SECONDS = 120
MODEL_ACTION_TIMEOUT_SECONDS = int(os.getenv("OLLAMA_MODEL_ACTION_TIMEOUT_SECONDS", "1800"))

MODEL_CATALOG: List[Dict[str, Any]] = [
    {
        "name": "qwen2.5-coder:1.5b",
        "display_name": "Qwen2.5 Coder 1.5B",
        "family": "Qwen2.5 Coder",
        "parameters": "1.5B",
        "disk_gb": 1.0,
        "memory_gb": 3,
        "description": "Small coding model for installer validation and lightweight repository tasks.",
    },
    {
        "name": "qwen2.5-coder:3b",
        "display_name": "Qwen2.5 Coder 3B",
        "family": "Qwen2.5 Coder",
        "parameters": "3B",
        "disk_gb": 2.0,
        "memory_gb": 5,
        "description": "Balanced coding model for modest VMs with better reasoning than the smallest option.",
    },
    {
        "name": "deepseek-coder:1.3b",
        "display_name": "DeepSeek Coder 1.3B",
        "family": "DeepSeek Coder",
        "parameters": "1.3B",
        "disk_gb": 0.8,
        "memory_gb": 3,
        "description": "Compact code-specialized model for low-memory systems.",
    },
    {
        "name": "deepseek-coder:6.7b-instruct-q4_K_M",
        "display_name": "DeepSeek Coder 6.7B Instruct",
        "family": "DeepSeek Coder",
        "parameters": "6.7B",
        "disk_gb": 4.1,
        "memory_gb": 8,
        "description": "Larger instruction-tuned coding model for stronger local code edits.",
    },
    {
        "name": "qwen2.5-coder:7b",
        "display_name": "Qwen2.5 Coder 7B",
        "family": "Qwen2.5 Coder",
        "parameters": "7B",
        "disk_gb": 4.7,
        "memory_gb": 8,
        "description": "General-purpose local coding model with a good quality-to-size tradeoff.",
    },
    {
        "name": "codellama:7b",
        "display_name": "Code Llama 7B",
        "family": "Code Llama",
        "parameters": "7B",
        "disk_gb": 3.8,
        "memory_gb": 8,
        "description": "Established open code model for completion and repository tasks.",
    },
    {
        "name": "llama3.2:3b",
        "display_name": "Llama 3.2 3B",
        "family": "Llama",
        "parameters": "3B",
        "disk_gb": 2.0,
        "memory_gb": 5,
        "description": "Small general chat model for fast local conversations.",
    },
    {
        "name": "mistral:7b",
        "display_name": "Mistral 7B",
        "family": "Mistral",
        "parameters": "7B",
        "disk_gb": 4.1,
        "memory_gb": 8,
        "description": "General instruction model for non-coding chat and planning tasks.",
    },
]


def list_installed_models() -> List[Dict[str, Any]]:
    response = requests.get(
        f"{OLLAMA_URL}/api/tags",
        timeout=REQUEST_TIMEOUT_SECONDS,
    )
    response.raise_for_status()
    payload = response.json()
    return payload.get("models", [])


def list_installed_model_names() -> List[str]:
    return [model.get("name", "") for model in list_installed_models() if model.get("name")]


def bytes_to_gb(size_bytes: Any) -> float:
    try:
        return round(float(size_bytes) / (1024 ** 3), 2)
    except (TypeError, ValueError):
        return 0.0


def list_component_models() -> List[Dict[str, Any]]:
    installed_models = list_installed_models()
    installed_by_name = {
        model.get("name"): model
        for model in installed_models
        if model.get("name")
    }

    components: List[Dict[str, Any]] = []
    catalog_names = {model["name"] for model in MODEL_CATALOG}

    for model in MODEL_CATALOG:
        installed = installed_by_name.get(model["name"])
        installed_size_gb = bytes_to_gb(installed.get("size")) if installed else 0.0
        details = (installed.get("details") or {}) if installed else {}
        components.append(
            {
                **model,
                "installed": bool(installed),
                "installed_size_gb": installed_size_gb,
                "modified_at": installed.get("modified_at", "") if installed else "",
                "details": details,
            }
        )

    for name, installed in installed_by_name.items():
        if name in catalog_names:
            continue

        details = installed.get("details") or {}
        components.append(
            {
                "name": name,
                "display_name": name,
                "family": details.get("family", "Unknown"),
                "parameters": details.get("parameter_size", "Unknown"),
                "disk_gb": bytes_to_gb(installed.get("size")),
                "memory_gb": None,
                "description": "Installed in Ollama, but not part of this curated component list.",
                "installed": True,
                "installed_size_gb": bytes_to_gb(installed.get("size")),
                "modified_at": installed.get("modified_at", ""),
                "details": details,
            }
        )

    return components


def install_model(name: str) -> Dict[str, Any]:
    if name not in {model["name"] for model in MODEL_CATALOG}:
        raise ValueError(f"Model '{name}' is not in the managed component catalog.")

    response = requests.post(
        f"{OLLAMA_URL}/api/pull",
        json={"name": name, "stream": False},
        timeout=MODEL_ACTION_TIMEOUT_SECONDS,
    )
    response.raise_for_status()
    return response.json() if response.text else {"status": "success"}


def uninstall_model(name: str) -> Dict[str, Any]:
    response = requests.delete(
        f"{OLLAMA_URL}/api/delete",
        json={"name": name},
        timeout=REQUEST_TIMEOUT_SECONDS,
    )
    response.raise_for_status()
    return {"status": "success", "name": name}


def chat_with_model(model: str, messages: List[Dict[str, str]]) -> Dict[str, Any]:
    response = requests.post(
        f"{OLLAMA_URL}/api/chat",
        json={
            "model": model,
            "messages": messages,
            "stream": False,
        },
        timeout=REQUEST_TIMEOUT_SECONDS,
    )
    response.raise_for_status()
    return response.json()
