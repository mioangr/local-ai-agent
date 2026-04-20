#!/bin/bash
# =============================================================================
# Local AI Agent Updater
# =============================================================================

set -euo pipefail

UPDATER_SELF_VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOCAL_MANIFEST="$SCRIPT_DIR/version.json"
UPDATE_REPO="${LOCAL_AI_AGENT_UPDATE_REPO:-mioangr/local-ai-agent}"
UPDATE_BRANCH="${LOCAL_AI_AGENT_UPDATE_BRANCH:-main}"
RAW_BASE_URL="${LOCAL_AI_AGENT_UPDATE_RAW_BASE_URL:-https://raw.githubusercontent.com/$UPDATE_REPO/$UPDATE_BRANCH}"
REMOTE_MANIFEST_URL="$RAW_BASE_URL/program-files/updater/version.json"
REMOTE_UPDATER_URL="$RAW_BASE_URL/program-files/updater/updater.sh"

COMMAND="${1:-status}"
OUTPUT_MODE="${2:-text}"

if [[ "$COMMAND" != "status" && "$COMMAND" != "apply" ]]; then
    echo "Usage: $0 [status|apply] [--json]"
    exit 1
fi

if [[ "$OUTPUT_MODE" != "text" && "$OUTPUT_MODE" != "--json" ]]; then
    echo "Usage: $0 [status|apply] [--json]"
    exit 1
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

json_get() {
    local file_path="$1"
    local field_name="$2"

    python3 - "$file_path" "$field_name" <<'PY'
import json
import sys

file_path, field_name = sys.argv[1], sys.argv[2]
with open(file_path, "r", encoding="utf-8") as handle:
    data = json.load(handle)
value = data.get(field_name)
if value is None:
    print("")
elif isinstance(value, bool):
    print("true" if value else "false")
elif isinstance(value, list):
    for item in value:
        print(item)
else:
    print(value)
PY
}

version_gt() {
    local left="$1"
    local right="$2"

    [[ "$left" != "$right" && "$(printf '%s\n%s\n' "$left" "$right" | sort -V | tail -n 1)" == "$left" ]]
}

safe_relative_path() {
    local relative_path="$1"

    if [[ -z "$relative_path" || "$relative_path" == /* || "$relative_path" == *".."* ]]; then
        return 1
    fi

    return 0
}

emit_result() {
    local result_status="$1"
    local message="$2"
    local installed_version="$3"
    local available_version="$4"
    local requires_full_setup="$5"
    local minimum_setup_version="$6"
    local updated_files="$7"

    if [[ "$OUTPUT_MODE" == "--json" ]]; then
        python3 - "$result_status" "$message" "$installed_version" "$available_version" "$requires_full_setup" "$minimum_setup_version" "$updated_files" <<'PY'
import json
import sys

status, message, installed, available, requires_full_setup, minimum_setup_version, updated_files = sys.argv[1:]
payload = {
    "status": status,
    "message": message,
    "installed_version": installed,
    "available_version": available,
    "requires_full_setup": requires_full_setup == "true",
    "minimum_setup_version": minimum_setup_version,
    "updated_files": [item for item in updated_files.split("\n") if item],
}
print(json.dumps(payload))
PY
        return
    fi

    echo "$message"
    if [[ -n "$installed_version" ]]; then
        echo "Installed version: $installed_version"
    fi
    if [[ -n "$available_version" ]]; then
        echo "Available version: $available_version"
    fi
    if [[ -n "$updated_files" ]]; then
        echo "Updated files:"
        printf '%s\n' "$updated_files"
    fi
}

download_file() {
    local source_url="$1"
    local destination_path="$2"

    curl -fsSL "$source_url" -o "$destination_path"
}

ensure_local_manifest() {
    if [[ ! -f "$LOCAL_MANIFEST" ]]; then
        emit_result "error" "Local updater manifest not found at $LOCAL_MANIFEST." "" "" "false" "" ""
        exit 1
    fi
}

ensure_remote_manifest() {
    download_file "$REMOTE_MANIFEST_URL" "$TMP_DIR/remote-version.json"
}

ensure_local_manifest
ensure_remote_manifest

LOCAL_VERSION="$(json_get "$LOCAL_MANIFEST" "version" | head -n 1)"
LOCAL_SETUP_VERSION="$(json_get "$LOCAL_MANIFEST" "setup_version" | head -n 1)"
LOCAL_UPDATER_VERSION="$(json_get "$LOCAL_MANIFEST" "updater_version" | head -n 1)"
REMOTE_VERSION="$(json_get "$TMP_DIR/remote-version.json" "version" | head -n 1)"
REMOTE_SETUP_VERSION="$(json_get "$TMP_DIR/remote-version.json" "setup_version" | head -n 1)"
REMOTE_UPDATER_VERSION="$(json_get "$TMP_DIR/remote-version.json" "updater_version" | head -n 1)"
REQUIRES_FULL_SETUP="$(json_get "$TMP_DIR/remote-version.json" "requires_full_setup" | head -n 1)"
MINIMUM_SETUP_VERSION="$(json_get "$TMP_DIR/remote-version.json" "minimum_setup_version" | head -n 1)"

if [[ -z "$LOCAL_UPDATER_VERSION" ]]; then
    LOCAL_UPDATER_VERSION="$UPDATER_SELF_VERSION"
fi

if [[ "$COMMAND" == "status" ]]; then
    if version_gt "$REMOTE_VERSION" "$LOCAL_VERSION"; then
        if [[ "$REQUIRES_FULL_SETUP" == "true" ]] || version_gt "$MINIMUM_SETUP_VERSION" "$LOCAL_SETUP_VERSION"; then
            emit_result \
                "full-setup-required" \
                "Version $REMOTE_VERSION is available, but it requires running the full setup process." \
                "$LOCAL_VERSION" \
                "$REMOTE_VERSION" \
                "$REQUIRES_FULL_SETUP" \
                "$MINIMUM_SETUP_VERSION" \
                ""
            exit 0
        fi

        emit_result \
            "update-available" \
            "Version $REMOTE_VERSION is available for live update." \
            "$LOCAL_VERSION" \
            "$REMOTE_VERSION" \
            "$REQUIRES_FULL_SETUP" \
            "$MINIMUM_SETUP_VERSION" \
            ""
        exit 0
    fi

    emit_result \
        "up-to-date" \
        "This installation is already up to date." \
        "$LOCAL_VERSION" \
        "$REMOTE_VERSION" \
        "$REQUIRES_FULL_SETUP" \
        "$MINIMUM_SETUP_VERSION" \
        ""
    exit 0
fi

if ! version_gt "$REMOTE_VERSION" "$LOCAL_VERSION"; then
    emit_result \
        "up-to-date" \
        "No live update is needed." \
        "$LOCAL_VERSION" \
        "$REMOTE_VERSION" \
        "$REQUIRES_FULL_SETUP" \
        "$MINIMUM_SETUP_VERSION" \
        ""
    exit 0
fi

if [[ "$REQUIRES_FULL_SETUP" == "true" ]] || version_gt "$MINIMUM_SETUP_VERSION" "$LOCAL_SETUP_VERSION"; then
    emit_result \
        "full-setup-required" \
        "Live update is blocked for version $REMOTE_VERSION. Run the full setup instead." \
        "$LOCAL_VERSION" \
        "$REMOTE_VERSION" \
        "$REQUIRES_FULL_SETUP" \
        "$MINIMUM_SETUP_VERSION" \
        ""
    exit 0
fi

if [[ "${LOCAL_AI_AGENT_UPDATER_BOOTSTRAPPED:-0}" != "1" ]] && version_gt "$REMOTE_UPDATER_VERSION" "$LOCAL_UPDATER_VERSION"; then
    download_file "$REMOTE_UPDATER_URL" "$TMP_DIR/remote-updater.sh"
    chmod +x "$TMP_DIR/remote-updater.sh"
    export LOCAL_AI_AGENT_UPDATER_BOOTSTRAPPED=1
    exec "$TMP_DIR/remote-updater.sh" apply "$OUTPUT_MODE"
fi

mapfile -t UPDATE_FILES < <(json_get "$TMP_DIR/remote-version.json" "live_update_files")
UPDATED_FILES=()

for relative_path in "${UPDATE_FILES[@]}"; do
    if ! safe_relative_path "$relative_path"; then
        emit_result \
            "error" \
            "Remote manifest contained an unsafe path: $relative_path" \
            "$LOCAL_VERSION" \
            "$REMOTE_VERSION" \
            "$REQUIRES_FULL_SETUP" \
            "$MINIMUM_SETUP_VERSION" \
            ""
        exit 1
    fi

    destination_path="$INSTALL_ROOT/$relative_path"
    staged_path="$TMP_DIR/$relative_path"
    mkdir -p "$(dirname "$staged_path")"
    download_file "$RAW_BASE_URL/$relative_path" "$staged_path"
done

for relative_path in "${UPDATE_FILES[@]}"; do
    destination_path="$INSTALL_ROOT/$relative_path"
    staged_path="$TMP_DIR/$relative_path"
    mkdir -p "$(dirname "$destination_path")"
    install_mode="0644"
    if [[ "$relative_path" == *.sh ]]; then
        install_mode="0755"
    fi
    install -m "$install_mode" "$staged_path" "$destination_path"
    UPDATED_FILES+=("$relative_path")
done

emit_result \
    "updated" \
    "Live update completed successfully." \
    "$LOCAL_VERSION" \
    "$REMOTE_VERSION" \
    "$REQUIRES_FULL_SETUP" \
    "$MINIMUM_SETUP_VERSION" \
    "$(printf '%s\n' "${UPDATED_FILES[@]}")"
