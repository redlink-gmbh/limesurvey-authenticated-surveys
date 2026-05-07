# package.sh — config.xml Auto-Update

## What was done

`package.sh` was extended to automatically update `config.xml` inside the staging directory before zipping. The source file is never touched — only the copy in `PACKAGE_ROOT`.

The following fields are updated using `xmlstarlet ed -L` (in-place XML editing):

| Field | Value |
|---|---|
| `<version>` | cleaned semver from `RAW_VERSION` |
| `<lastUpdate>` | current date at script runtime (`YYYY-MM-DD`) |
| `<author>` | resolved owner (see below) |
| `<authorUrl>` | `https://github.com/<owner>` |

---

## Version Resolution

`RAW_VERSION` is resolved in this order:

1. `VERSION` env var
2. `GITHUB_REF_NAME` (set automatically by GitHub Actions)
3. Last git tag via `git describe --tags --abbrev=0`

Prefixes like `refs/tags/v` and leading `v` are stripped before use.

The cleaned version is then validated against `^[0-9]+\.[0-9]+\.[0-9]+$`. This **semver guard** is what prevents PR pipeline builds — which use a `run-<id>` string as the version — from triggering the config update.

---

## Owner Resolution

`author` and `authorUrl` are resolved in this order:

1. `GITHUB_REPOSITORY_OWNER` (set automatically by GitHub Actions)
2. Owner extracted from `git remote get-url origin` (works for both `https://` and `git@` formats)

If neither resolves, both fields are left as-is in `config.xml`.

---

## Pipeline Change

`package.yml` was updated to install `xmlstarlet` alongside `zip`:

```yaml
- name: Install zip and xmlstarlet
  run: sudo apt-get update && sudo apt-get install -y zip xmlstarlet
```
