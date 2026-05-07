#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Source files of the plugin.
# Default: <repo>/AuthSurvey
SOURCE_DIR="${1:-${SOURCE_DIR:-${REPO_ROOT}/AuthSurvey}}"

# Folder name inside the zip.
PACKAGE_DIR_NAME="${PACKAGE_DIR_NAME:-AuthSurvey}"

# Output dir, default: <repo>/dist
OUTPUT_DIR="${2:-${OUTPUT_DIR:-${REPO_ROOT}/dist}}"

RAW_VERSION="${VERSION:-${GITHUB_REF_NAME:-$(git -C "${REPO_ROOT}" describe --tags --abbrev=0 2>/dev/null || true)}}"
SAFE_VERSION="$(printf '%s' "${RAW_VERSION}" | tr '/[:space:]' '-' | tr -cd '[:alnum:]._-')"

if [[ ! -d "${SOURCE_DIR}" ]]; then
  echo "Source directory not found: ${SOURCE_DIR}" >&2
  exit 1
fi

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

cp -r "${SOURCE_DIR}/." "${PACKAGE_ROOT}/"

CLEAN_VERSION="$(printf '%s' "${RAW_VERSION}" | sed 's|refs/tags/||;s|^v||')"
if [[ -f "${PACKAGE_ROOT}/config.xml" ]] && [[ "${CLEAN_VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  UPDATE_DATE="$(date +%Y-%m-%d)"
  _remote_url="$(git -C "${REPO_ROOT}" remote get-url origin 2>/dev/null || true)"
  _remote_owner="$(printf '%s' "${_remote_url}" | sed 's|.*github\.com[:/]\([^/]*\)/.*|\1|')"
  REPO_AUTHOR="${GITHUB_REPOSITORY_OWNER:-${_remote_owner}}"
  REPO_AUTHOR_URL="${REPO_AUTHOR:+${GITHUB_SERVER_URL:-https://github.com}/${REPO_AUTHOR}}"

  _xmlargs=(
    -u "/config/metadata/version"    -v "${CLEAN_VERSION}"
    -u "/config/metadata/lastUpdate" -v "${UPDATE_DATE}"
  )
  [[ -n "${REPO_AUTHOR}" ]]     && _xmlargs+=(-u "/config/metadata/author"    -v "${REPO_AUTHOR}")
  [[ -n "${REPO_AUTHOR_URL}" ]] && _xmlargs+=(-u "/config/metadata/authorUrl" -v "${REPO_AUTHOR_URL}")

  xmlstarlet ed "${_xmlargs[@]}" \
    "${PACKAGE_ROOT}/config.xml" > "${PACKAGE_ROOT}/config.xml.tmp"
  mv "${PACKAGE_ROOT}/config.xml.tmp" "${PACKAGE_ROOT}/config.xml"
fi

rm -f "${ZIP_PATH}"

(
  cd "${STAGING_DIR}"
  zip -r "${ZIP_PATH}" "${PACKAGE_DIR_NAME}"
)

echo "Created package: ${ZIP_PATH}"