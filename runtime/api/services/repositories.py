#!/usr/bin/env python3
"""Repository access service."""

from runtime.shared.repos import get_repository_map, list_repositories


def get_all_projects():
    return list_repositories()


def get_project_map():
    return get_repository_map()
