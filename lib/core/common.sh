#!/usr/bin/env bash
set -euo pipefail

# ────────────────────────────────────────────────
# 🌐 InfraForge — Core Common Functions
# Free · Local · User-Owned · Forever
# ────────────────────────────────────────────────

# ────────────────────────────────
# 🧩 Stack Registry
# ────────────────────────────────
declare -a INFRAFORGE_STACKS=(
  terraform
  docker
  helm
  jenkins
  monitoring
  security
  argocd
  ansible
  k8s
  aws
)
export INFRAFORGE_STACKS

# ────────────────────────────────
# 🏗️ Core Paths
# ────────────────────────────────
INFRAFORGE_ROOT="${INFRAFORGE_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
INFRAFORGE_CONFIG_DIR="${INFRAFORGE_ROOT}/configs"
INFRAFORGE_GENERATED_DIR="${INFRAFORGE_ROOT}/generated"
INFRAFORGE_TEMPLATES_DIR="${INFRAFORGE_ROOT}/templates"

# 🌱 Per-user cache and logs (multi-user safe)
INFRAFORGE_CACHE_DIR="${HOME}/.infraforge/cache"
INFRAFORGE_LOG_DIR="${HOME}/.infraforge/logs"
mkdir -p "${INFRAFORGE_CACHE_DIR}" "${INFRAFORGE_LOG_DIR}"

INFRAFORGE_REMOTE_CONF_BASE="https://raw.githubusercontent.com/InfraForgeLabs/InfraForge/main/configs"
INFRAFORGE_REPO_API="https://api.github.com/repos/InfraForgeLabs/InfraForge"

# ────────────────────────────────
# 🏷️ Version Detection (version.json first)
# ────────────────────────────────
INFRAFORGE_VERSION=""
CACHE_VERSION_FILE="${INFRAFORGE_CACHE_DIR}/VERSION"
VERSION_JSON_LOCAL="https://infraforgelabs.in/meta/infraforge/version.json"

# 1️⃣ Local installed version.json (authoritative)
if [[ -f "${VERSION_JSON_LOCAL}" ]]; then
  INFRAFORGE_VERSION="$(
    grep -o '"latest_version"[[:space:]]*:[[:space:]]*"[^"]*"' \
      "${VERSION_JSON_LOCAL}" \
    | sed 's/.*"latest_version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/v\1/'
  )"
fi

# 2️⃣ Cached version (offline-safe)
if [[ -z "${INFRAFORGE_VERSION}" && -f "${CACHE_VERSION_FILE}" ]]; then
  INFRAFORGE_VERSION="$(cat "${CACHE_VERSION_FILE}")"
fi

# 3️⃣ Git tag (developer mode only)
if [[ -z "${INFRAFORGE_VERSION}" && -d "${INFRAFORGE_ROOT}/.git" ]] && command -v git >/dev/null 2>&1; then
  INFRAFORGE_VERSION="$(git -C "${INFRAFORGE_ROOT}" describe --tags --abbrev=0 2>/dev/null || true)"
fi

# 4️⃣ Final fallback
[[ -z "${INFRAFORGE_VERSION}" ]] && INFRAFORGE_VERSION="v0.0.0-dev"

# Cache resolved version
echo "${INFRAFORGE_VERSION}" > "${CACHE_VERSION_FILE}"

export INFRAFORGE_VERSION

# ────────────────────────────────
# 🌐 Online / Offline Mode
# ────────────────────────────────
if curl -sSfI "https://raw.githubusercontent.com/InfraForgeLabs/InfraForge/main/README.md" >/dev/null 2>&1; then
  INFRAFORGE_MODE="online"
else
  INFRAFORGE_MODE="offline"
fi
export INFRAFORGE_MODE

# ────────────────────────────────
# 🪶 Logging Helpers
# ────────────────────────────────
log()   { printf "[%s] %s\n" "$(date +'%H:%M:%S')" "$*"; }
warn()  { printf "[%s] WARN: %s\n" "$(date +'%H:%M:%S')" "$*" >&2; }
err()   { printf "[%s] ERROR: %s\n" "$(date +'%H:%M:%S')" "$*" >&2; }
fatal() { err "$*"; exit 1; }
require() { command -v "$1" >/dev/null 2>&1 || fatal "Missing dependency: $1"; }

# ────────────────────────────────
# 🧩 Placeholder Rendering
# ────────────────────────────────
render_file_placeholders() {
  local infile="$1" outfile="$2"
  local tmp; tmp="$(mktemp)"
  cp "${infile}" "${tmp}"

  mapfile -t keys < <(grep -o '{{[A-Z0-9_]\+}}' "${tmp}" | tr -d '{}' | sort -u || true)
  if [[ "${#keys[@]:-0}" -gt 0 ]]; then
    for k in "${keys[@]}"; do
      local value="${!k-}"
      if [[ -n "${value:-}" ]]; then
        local esc; esc="$(printf '%s' "${value}" | sed 's/[&/\]/\\&/g')"
        sed -i "s/{{${k}}}/${esc}/g" "${tmp}"
      fi
    done
  fi
  mkdir -p "$(dirname "${outfile}")"
  mv "${tmp}" "${outfile}"
}

# ────────────────────────────────
# 🌲 Directory Tree Printer
# ────────────────────────────────
show_tree() {
  local dir="$1"
  [[ -d "${dir}" ]] || fatal "Directory not found: ${dir}"
  (cd "${dir}" && find . -print | sed '1d; s,[^/]*/,|   ,g;s,| *\([^| ]\),|-- \1,')
}
