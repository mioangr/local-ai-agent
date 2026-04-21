#!/usr/bin/env python3
"""Task helpers backed by Redis."""

from __future__ import annotations

import json
import uuid
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

import redis


QUEUE_NAME = "task:queue"
TASK_INDEX_KEY = "tasks:index"
RESULT_CHANNEL = "task:results"
ERROR_CHANNEL = "task:errors"
TASK_STATUS_VALUES = {"queued", "running", "completed", "failed"}


def utc_now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def get_task_key(task_id: str) -> str:
    return f"task:{task_id}"


def create_task_payload(
    project: str,
    instruction: str,
    model: Optional[str] = None,
    submitted_by: Optional[str] = None,
) -> Dict[str, str]:
    now = utc_now_iso()
    payload = {
        "task_id": str(uuid.uuid4()),
        "project": project,
        "instruction": instruction,
        "model": model or "",
        "submitted_by": submitted_by or "",
        "status": "queued",
        "created_at": now,
        "updated_at": now,
        "pr_url": "",
        "error": "",
        "success": "",
    }
    return payload


def submit_task(redis_client: redis.Redis, task: Dict[str, str]) -> Dict[str, str]:
    task_id = task["task_id"]
    redis_client.hset(get_task_key(task_id), mapping=task)
    redis_client.lpush(TASK_INDEX_KEY, task_id)
    redis_client.ltrim(TASK_INDEX_KEY, 0, 199)
    redis_client.rpush(QUEUE_NAME, json.dumps(task))
    return task


def update_task(
    redis_client: redis.Redis,
    task_id: str,
    *,
    status: Optional[str] = None,
    **fields: Any,
) -> Dict[str, Any]:
    mapping: Dict[str, str] = {key: _stringify(value) for key, value in fields.items() if value is not None}

    if status:
        if status not in TASK_STATUS_VALUES:
            raise ValueError(f"Unsupported task status: {status}")
        mapping["status"] = status

    mapping["updated_at"] = utc_now_iso()

    if mapping:
        redis_client.hset(get_task_key(task_id), mapping=mapping)

    return get_task(redis_client, task_id) or {}


def get_task(redis_client: redis.Redis, task_id: str) -> Optional[Dict[str, Any]]:
    data = redis_client.hgetall(get_task_key(task_id))
    if not data:
        return None
    return _deserialize_task(data)


def list_tasks(redis_client: redis.Redis, limit: int = 20) -> List[Dict[str, Any]]:
    task_ids = redis_client.lrange(TASK_INDEX_KEY, 0, max(limit - 1, 0))
    tasks: List[Dict[str, Any]] = []
    for task_id in task_ids:
        task = get_task(redis_client, task_id)
        if task:
            tasks.append(task)
    return tasks


def _stringify(value: Any) -> str:
    if isinstance(value, bool):
        return "true" if value else "false"
    return str(value)


def _deserialize_task(data: Dict[str, str]) -> Dict[str, Any]:
    task = dict(data)
    success_raw = task.get("success", "")
    if success_raw == "":
        task["success"] = None
    else:
        task["success"] = success_raw.lower() == "true"
    return task
