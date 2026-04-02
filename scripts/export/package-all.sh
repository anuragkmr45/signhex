#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  bash scripts/export/package-all.sh --release <release-id> [--electron-platform windows|macos|linux|all-supported]
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RELEASE_ID=""
ELECTRON_PLATFORM="all-supported"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --release)
      RELEASE_ID="${2:-}"
      shift 2
      ;;
    --electron-platform)
      ELECTRON_PLATFORM="${2:-}"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$RELEASE_ID" ]]; then
  usage
  exit 1
fi

bash "$SCRIPT_DIR/package-server.sh" --release "$RELEASE_ID"
bash "$SCRIPT_DIR/package-cms.sh" --release "$RELEASE_ID"
bash "$SCRIPT_DIR/package-electron.sh" --release "$RELEASE_ID" --platform "$ELECTRON_PLATFORM"
