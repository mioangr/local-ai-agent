#!/usr/bin/env python3
"""Redis client factory for the API service."""

import os

import redis


REDIS_URL = os.getenv("REDIS_URL", "redis://redis:6379")


def get_redis_client() -> redis.Redis:
    return redis.Redis.from_url(REDIS_URL, decode_responses=True)

