#!/usr/bin/env bash
set -euo pipefail

# ────────────────────────────────────────────────
# 🌐 InfraForge — Show Command
# Free · Local · Open · Forever
# ────────────────────────────────────────────────
# Usage:
#   source lib/core/common.sh
#   source lib/core/show.sh
#   show_stack <stack> [project]
# ────────────────────────────────────────────────

show_stack() {
  local stack="$1"
  local project="${2:-${PROJECT:-${stack}-project}}"
  local gen_dir="${INFRAFORGE_GENERATED_DIR}/${project}"

  [[ -d "${gen_dir}" ]] || fatal "Generated project not found: ${gen_dir}"

  log "📂 Displaying generated ${stack} project: ${project}"
  echo "────────────────────────────────────────────"

  # Directory tree
  show_tree "${gen_dir}"
  echo "────────────────────────────────────────────"

  # Count summary
  local total_files resolved unresolved
  total_files="$(find "${gen_dir}" -type f | wc -l | tr -d ' ')"
  resolved="$(grep -Rho '{{[A-Z0-9_]\+}}' "${gen_dir}" 2>/dev/null | wc -l | tr -d ' ' || true)"
  unresolved=$(( resolved > 0 ? resolved : 0 ))

  echo "📊 Summary:"
  echo "  • Stack: ${stack}"
  echo "  • Project: ${project}"
  echo "  • Files: ${total_files}"
  echo "  • Unresolved placeholders: ${unresolved}"
  echo "  • Location: ${gen_dir}"
  echo "────────────────────────────────────────────"

  if (( unresolved > 0 )); then
    warn "⚠️  ${unresolved} unresolved placeholders remain in templates."
    echo "💡 Run: infraforge validate ${stack}"
  else
    log "✅ All placeholders resolved."
  fi
}
