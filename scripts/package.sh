#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

PLUGIN_DIR_NAME="${PLUGIN_DIR_NAME:-AuthSurvey}"
PLUGIN_DIR="${PLUGIN_DIR:-${REPO_ROOT}/${PLUGIN_DIR_NAME}}"
OUTPUT_DIR="${1:-${REPO_ROOT}/dist}"
VERSION="${VERSION:-}"

if [[ ! -d "${PLUGIN_DIR}" ]]; then
  echo "Plugin directory not found: ${PLUGIN_DIR}" >&2
  exit 1
fi

mkdir -p "${OUTPUT_DIR}"

if [[ -n "${VERSION}" ]]; then
  ZIP_NAME="${PLUGIN_DIR_NAME}-${VERSION}.zip"
else
  ZIP_NAME="${PLUGIN_DIR_NAME}.zip"
fi

ZIP_PATH="${OUTPUT_DIR}/${ZIP_NAME}"

rm -f "${ZIP_PATH}"

PARENT_DIR="$(dirname "${PLUGIN_DIR}")"
BASENAME="$(basename "${PLUGIN_DIR}")"

(
  cd "${PARENT_DIR}"
  zip -r "${ZIP_PATH}" "${BASENAME}" \
    -x "${BASENAME}/.git/*" \
    -x "${BASENAME}/.github/*" \
    -x "${BASENAME}/dist/*" \
    -x "${BASENAME}/node_modules/*" \
    -x "${BASENAME}/vendor/bin/*" \
    -x "${BASENAME}/tests/*" \
    -x "${BASENAME}/.DS_Store"
)

echo "Created package: ${ZIP_PATH}"