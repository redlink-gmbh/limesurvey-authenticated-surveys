#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Source files of the plugin.
# Default: repository root contains the plugin files.
SOURCE_DIR="${SOURCE_DIR:-${REPO_ROOT}}"

# Folder name inside the zip.
PACKAGE_DIR_NAME="${PACKAGE_DIR_NAME:-AuthSurvey}"

# Output dir, default: <repo>/dist
OUTPUT_DIR="${1:-${REPO_ROOT}/dist}"

RAW_VERSION="${VERSION:-${GITHUB_REF_NAME:-}}"
SAFE_VERSION="$(printf '%s' "${RAW_VERSION}" | tr '/[:space:]' '-' | tr -cd '[:alnum:]._-')"

mkdir -p "${OUTPUT_DIR}"

if [[ -n "${SAFE_VERSION}" ]]; then
  ZIP_NAME="${PACKAGE_DIR_NAME}-${SAFE_VERSION}.zip"
else
  ZIP_NAME="${PACKAGE_DIR_NAME}.zip"
fi

ZIP_PATH="$(cd "${OUTPUT_DIR}" && pwd)/${ZIP_NAME}"
STAGING_DIR="$(mktemp -d)"
PACKAGE_ROOT="${STAGING_DIR}/${PACKAGE_DIR_NAME}"

cleanup() {
  rm -rf "${STAGING_DIR}"
}
trap cleanup EXIT

mkdir -p "${PACKAGE_ROOT}"

rsync -a \
  --exclude '.git' \
  --exclude '.github' \
  --exclude 'dist' \
  --exclude 'scripts' \
  --exclude '.idea' \
  --exclude '.DS_Store' \
  --exclude 'node_modules' \
  --exclude 'vendor' \
  --exclude 'tests' \
  "${SOURCE_DIR}/" "${PACKAGE_ROOT}/"

rm -f "${ZIP_PATH}"

(
  cd "${STAGING_DIR}"
  zip -r "${ZIP_PATH}" "${PACKAGE_DIR_NAME}"
)

echo "Created package: ${ZIP_PATH}"