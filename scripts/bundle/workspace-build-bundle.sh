#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  bash scripts/bundle/workspace-build-bundle.sh [--skip-docker] [--profile all|qa|production] <site-name>

This is a transition convenience wrapper for a local workspace that contains:

- ../signhex-server
- ../signhex-nexus-core
- ../signage-screen

It builds product artifacts from the sibling repos, then calls the canonical
artifact-driven assembler:

  bash scripts/bundle/assemble-runtime-bundle.sh ...

Important:
- target QA and production machines still receive only runtime bundles
- the canonical platform workflow is artifact-driven
- this wrapper still requires Docker because it builds the backend image locally
EOF
}

SKIP_DOCKER="false"
PROFILE="all"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --skip-docker)
      SKIP_DOCKER="true"
      shift
      ;;
    --profile)
      PROFILE="${2:-}"
      shift 2
      ;;
    *)
      break
      ;;
  esac
done

SITE_NAME="${1:-}"
if [[ -z "$SITE_NAME" ]]; then
  usage
  exit 1
fi

case "$PROFILE" in
  all|qa|production)
    ;;
  *)
    echo "Unsupported profile: $PROFILE" >&2
    usage
    exit 1
    ;;
esac

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
WORKSPACE_ROOT="$(cd "$PLATFORM_ROOT/.." && pwd)"
SERVER_DIR="$WORKSPACE_ROOT/signhex-server"
CMS_DIR="$WORKSPACE_ROOT/signhex-nexus-core"
PLAYER_DIR="$WORKSPACE_ROOT/signage-screen"
ASSEMBLER_SCRIPT="$SCRIPT_DIR/assemble-runtime-bundle.sh"

require_command() {
  local command_name="$1"
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "$command_name is required on the build machine." >&2
    exit 1
  fi
}

require_directory() {
  local label="$1"
  local directory="$2"
  if [[ ! -d "$directory" ]]; then
    echo "$label directory not found: $directory" >&2
    exit 1
  fi
}

require_command docker
require_command npm
require_command tar
require_command bash

require_directory "Backend repo" "$SERVER_DIR"
require_directory "CMS repo" "$CMS_DIR"
require_directory "Electron repo" "$PLAYER_DIR"

PLAYER_ARTIFACTS_DIR="${PLAYER_ARTIFACTS_DIR:-$PLAYER_DIR/build}"
BACKEND_IMAGE_REF="${BACKEND_IMAGE_REF:-signhex-onprem-api:${SITE_NAME}}"

TEMP_WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/signhex-workspace-bundle.XXXXXX")"
cleanup_temp_work_dir() {
  rm -rf "$TEMP_WORK_DIR"
}
trap cleanup_temp_work_dir EXIT

BACKEND_IMAGE_ARCHIVE="$TEMP_WORK_DIR/${BACKEND_IMAGE_REF//[:\/]/-}.tar"
CMS_BUNDLE_ARCHIVE="$TEMP_WORK_DIR/signhex-nexus-core-${SITE_NAME}.tgz"

echo "Building backend image from $SERVER_DIR ..."
docker build -t "$BACKEND_IMAGE_REF" "$SERVER_DIR"
docker save -o "$BACKEND_IMAGE_ARCHIVE" "$BACKEND_IMAGE_REF"

echo "Building CMS bundle from $CMS_DIR ..."
(
  cd "$CMS_DIR"
  VITE_API_BASE_URL= \
  VITE_WS_BASE_URL= \
  VITE_WS_URL= \
  npm run build
)
tar -czf "$CMS_BUNDLE_ARCHIVE" -C "$CMS_DIR/dist" .

ARGS=()
if [[ "$SKIP_DOCKER" == "true" ]]; then
  ARGS+=(--skip-docker)
fi
ARGS+=(--profile "$PROFILE" "$SITE_NAME")

echo "Assembling runtime bundle through $ASSEMBLER_SCRIPT ..."
BACKEND_IMAGE_REF="$BACKEND_IMAGE_REF" \
BACKEND_IMAGE_ARCHIVE="$BACKEND_IMAGE_ARCHIVE" \
CMS_BUNDLE_SOURCE="$CMS_BUNDLE_ARCHIVE" \
PLAYER_ARTIFACTS_DIR="$PLAYER_ARTIFACTS_DIR" \
bash "$ASSEMBLER_SCRIPT" "${ARGS[@]}"
