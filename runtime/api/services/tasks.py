#!/usr/bin/env python3
"""Task service for the API gateway."""

from typing import Optional

from runtime.api.services.redis_client import get_redis_client
from runtime.shared.tasks import create_task_payload, get_task, list_tasks, submit_task


def create_and_submit_task(project: str, instruction: str, model: Optional[str], submitted_by: str):
    redis_client = get_redis_client()
    task = create_task_payload(
        project=project,
        instruction=instruction,
        model=model,
        submitted_by=submitted_by,
    )
    submit_task(redis_client, task)
    return get_task(redis_client, task["task_id"])


def get_task_by_id(task_id: str):
    return get_task(get_redis_client(), task_id)


def get_recent_tasks(limit: int = 20):
    return list_tasks(get_redis_client(), limit=limit)
