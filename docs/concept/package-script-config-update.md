# package.sh — config.xml Auto-Update

## Status

Tested and it works as expected.

## Goal

When `package.sh` runs with a version set, it should automatically update `config.xml` inside the staging directory before zipping. The source file is never modified.

## Fields to Update

| Field | Source | Fallback |
|---|---|---|
| `<version>` | `RAW_VERSION` stripped to semver (e.g. `1.1.0`) | skip — only runs when version is a valid semver |
| `<lastUpdate>` | current date at script runtime (`YYYY-MM-DD`) | same as above |
| `<author>` | `GITHUB_REPOSITORY_OWNER` → git remote owner | leave existing value |
| `<authorUrl>` | `GITHUB_SERVER_URL`/owner (e.g. `https://github.com/redlink-gmbh`) | leave existing value |

## Version Source Priority

`RAW_VERSION` is resolved in this order:
1. `VERSION` env var (explicit override)
2. `GITHUB_REF_NAME` (set automatically by GitHub Actions)
3. Last git tag via `git describe --tags --abbrev=0` (local runs)
4. Empty → config.xml update is skipped entirely

## Version Cleaning & Guard

`RAW_VERSION` may come in as:
- `refs/tags/v1.1.0` → strip `refs/tags/` and leading `v` → `1.1.0`
- `v1.1.0` → strip leading `v` → `1.1.0`
- `1.1.0` → use as-is

`CLEAN_VERSION` is validated against `^[0-9]+\.[0-9]+\.[0-9]+$` before proceeding. This prevents PR pipeline builds (which use `run-<id>` as version) from updating config.xml.

## Owner & Author URL Resolution

`author` and `authorUrl` are resolved in this order:

1. `GITHUB_REPOSITORY_OWNER` (set automatically by GitHub Actions)
2. Owner extracted from `git remote get-url origin` (local runs — works for both `https://` and `git@` remote formats)
3. Empty → both fields are left as-is in config.xml

- `authorUrl` = `${GITHUB_SERVER_URL:-https://github.com}/${owner}` (e.g. `https://github.com/redlink-gmbh`)

## Tool

`xmlstarlet ed -L` (in-place edit). Optional args built into a `_xmlargs` array to avoid quoting issues with conditional XPath flags.

## Pipeline Change

`package.yml` step: removed `rsync`, added `xmlstarlet`:
```yaml
- name: Install zip and xmlstarlet
  run: sudo apt-get update && sudo apt-get install -y zip xmlstarlet
```

## Placement in Script

After the `cp` into `PACKAGE_ROOT`, before the `zip`. Only executed when `CLEAN_VERSION` passes the semver regex.

## Conditions Summary

- config.xml update: only when `CLEAN_VERSION` matches `^[0-9]+\.[0-9]+\.[0-9]+$`
- `author` / `authorUrl`: only when owner resolves to a non-empty value
- Target: `${PACKAGE_ROOT}/config.xml` — never the source
