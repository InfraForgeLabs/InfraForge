#!/usr/bin/env bash
set -euo pipefail

# ────────────────────────────────────────────────
# 🌐 InfraForge — Core Common Functions
# Free · Local · Open · Forever
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
# 🏷️ Version Detection
# ────────────────────────────────
INFRAFORGE_VERSION=""
CACHE_VERSION_FILE="${INFRAFORGE_CACHE_DIR}/VERSION"

if [[ -d "${INFRAFORGE_ROOT}/.git" ]] && command -v git >/dev/null 2>&1; then
  INFRAFORGE_VERSION="$(git -C "${INFRAFORGE_ROOT}" describe --tags --abbrev=0 2>/dev/null || true)"
  [[ -n "${INFRAFORGE_VERSION}" ]] && echo "${INFRAFORGE_VERSION}" > "${CACHE_VERSION_FILE}"
fi

if [[ -z "${INFRAFORGE_VERSION:-}" ]]; then
  if curl -fsSL "${INFRAFORGE_REPO_API}/tags" -o /tmp/tags.json 2>/dev/null; then
    INFRAFORGE_VERSION="$(grep -m1 '"name":' /tmp/tags.json | sed -E 's/.*"name": *"([^"]+)".*/\1/')"
    [[ -n "${INFRAFORGE_VERSION}" ]] && echo "${INFRAFORGE_VERSION}" > "${CACHE_VERSION_FILE}"
  fi
fi

[[ -z "${INFRAFORGE_VERSION:-}" && -f "${CACHE_VERSION_FILE}" ]] && INFRAFORGE_VERSION="$(cat "${CACHE_VERSION_FILE}")"
[[ -z "${INFRAFORGE_VERSION:-}" ]] && INFRAFORGE_VERSION="v0.0.0-dev"

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
