#!/bin/bash
# ============================================================
# 🌀 Argo CD Universal Template Generator (v2.6)
# Interactive + CLI + Addons + RBAC + Notifications + Projects
# ============================================================

REPO_URL="https://raw.githubusercontent.com/InfraForgeLabs/InfraForge/main/ArgoCDTemplates"
OUT_DIR="generated"
CACHE_DIR=".cache/argocd-templates"
mkdir -p "$OUT_DIR" "$CACHE_DIR"

# --- Colors & Logging ---
timestamp() { date +"%H:%M:%S"; }
info()    { echo -e "\033[1;34m[$(timestamp)] $1\033[0m"; }
success() { echo -e "\033[1;32m[$(timestamp)] $1\033[0m"; }
warn()    { echo -e "\033[1;33m[$(timestamp)] $1\033[0m"; }
error()   { echo -e "\033[1;31m[$(timestamp)] $1\033[0m"; }

# --- Backspace-Capable Input ---
read_input() {
  local varname=$1; local prompt=$2; local default=$3; local value
  read -e -p "$prompt [$default]: " value
  eval $varname="'${value:-$default}'"
}

# --- Default Values ---
DEFAULT_MODE="app"
DEFAULT_TYPE="helm"
DEFAULT_APP="my-app"
DEFAULT_NS="default"
DEFAULT_GITREPO="git@github.com:org/repo.git"
DEFAULT_BRANCH="main"
DEFAULT_PROJECT="default"
DEFAULT_ATTACH="false"

MODE=${MODE:-$DEFAULT_MODE}
TYPE=${TYPE:-$DEFAULT_TYPE}
APP=${APP:-$DEFAULT_APP}
NS=${NS:-$DEFAULT_NS}
GITREPO=${GITREPO:-$DEFAULT_GITREPO}
BRANCH=${BRANCH:-$DEFAULT_BRANCH}
PROJECT=${PROJECT:-$DEFAULT_PROJECT}
ATTACH_ADDONS=${ATTACH_ADDONS:-$DEFAULT_ATTACH}

# --- Parse CLI Flags ---
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --mode) MODE="$2"; shift ;;
    --type) TYPE="$2"; shift ;;
    --app) APP="$2"; shift ;;
    --ns|--namespace) NS="$2"; shift ;;
    --repo) GITREPO="$2"; shift ;;
    --branch) BRANCH="$2"; shift ;;
    --project) PROJECT="$2"; shift ;;
    --addons) ADDONS_FLAGS="$2"; shift ;;
    --vars) VARS="$2"; shift ;;
    --attach-addons) ATTACH_ADDONS="$2"; shift ;;
    --help|-h)
      echo "============================================================"
      echo "🌀 Argo CD Template Generator v2.6 — Help & Usage Guide"
      echo "============================================================"
      echo ""
      echo "USAGE:"
      echo "  bash argocd-gen.sh [options]"
      echo ""
      echo "OPTIONS:"
      echo "  --mode <app|project|rbac|notify>       Template mode"
      echo "  --type <helm|kustomize|manifests|appset|dev|staging|prod|admin|developer|read-only|slack|email|webhook>"
      echo "  --app <app-name>                       Application name"
      echo "  --ns <namespace>                       Kubernetes namespace"
      echo "  --repo <git-url>                       Git repository URL"
      echo "  --branch <branch>                      Git branch"
      echo "  --project <argo-project>               Argo CD project name"
      echo "  --addons <1,2,3>                       Add addons by number"
      echo "  --vars <key=value,...>                 Variables for Slack, Email, Webhook"
      echo "  --attach-addons <true|false>           Attach addon snippets into main YAML"
      echo ""
      echo "EXAMPLES:"
      echo "  bash argocd-gen.sh --mode app --type helm --app web --repo git@github.com:org/repo.git"
      echo "  bash argocd-gen.sh --mode project --type dev"
      echo "  bash argocd-gen.sh --mode rbac --type admin"
      echo "  bash argocd-gen.sh --mode notify --type slack --vars slacktoken=xoxb-123 --attach-addons true"
      echo ""
      exit 0 ;;
    *) warn "⚠️ Unknown flag: $1" ;;
  esac
  shift
done

# --- Parse Vars ---
if [ -n "$VARS" ]; then
  IFS=',' read -ra VAR_ARRAY <<< "$VARS"
  for v in "${VAR_ARRAY[@]}"; do
    key=$(echo "$v" | cut -d'=' -f1)
    value=$(echo "$v" | cut -d'=' -f2-)
    eval "$key='$value'"
  done
fi

# --- Online Detection ---
CHECK_URL="$REPO_URL/apps/app-helm.yaml"
if curl -sfI "$CHECK_URL" >/dev/null 2>&1; then
  ONLINE=true
  success "🌐 Online mode detected — templates will be fetched from GitHub."
else
  ONLINE=false
  warn "⚠️ Offline mode — using cached or local templates."
fi

# --- Auto-help hint ---
if [ $# -eq 0 ]; then
  echo ""
  info "💡 Tip: Run 'bash argocd-gen.sh --help' for automation flags & examples."
  echo ""
fi

# --- Interactive Input ---
if [ $# -eq 0 ]; then
  echo "============================================"
  info " 🌀 Argo CD Universal Template Generator"
  echo "============================================"
  echo "Select template type:"
  echo "1) Application (Helm / Kustomize / Manifests / AppSet)"
  echo "2) Project (Dev / Staging / Prod)"
  echo "3) RBAC Configuration"
  echo "4) Notifications Setup"
  read_input mode "Select option [1-4]" "1"
  case $mode in
    1) MODE="app"; read_input TYPE "Enter template type (helm/kustomize/manifests/appset)" "$DEFAULT_TYPE" ;;
    2) MODE="project"; read_input TYPE "Enter project type (dev/staging/prod)" "dev" ;;
    3) MODE="rbac"; read_input TYPE "Enter RBAC type (admin/developer/read-only)" "admin" ;;
    4) MODE="notify"; read_input TYPE "Enter notification type (slack/email/webhook)" "slack" ;;
    *) MODE="app" ;;
  esac
  read_input APP "Enter app name" "$DEFAULT_APP"
  read_input NS "Enter namespace" "$DEFAULT_NS"
  read_input GITREPO "Enter repo URL" "$DEFAULT_GITREPO"
  read_input BRANCH "Enter branch" "$DEFAULT_BRANCH"
  read_input PROJECT "Enter project name" "$DEFAULT_PROJECT"
fi

DEST_DIR="$OUT_DIR/$APP"
mkdir -p "$DEST_DIR"

# --- Template Selector ---
case $MODE in
  app)
    case $TYPE in
      helm|1) path="apps/app-helm.yaml" ;;
      kustomize|2) path="apps/app-kustomize.yaml" ;;
      manifests|3) path="apps/app-manifests.yaml" ;;
      appset|4) path="apps/appset-git.yaml" ;;
      *) error "Invalid application type"; exit 1 ;;
    esac ;;
  project)
    case $TYPE in
      dev|1) path="projects/dev-project.yaml" ;;
      staging|2) path="projects/staging-project.yaml" ;;
      prod|3) path="projects/prod-project.yaml" ;;
      *) error "Invalid project type"; exit 1 ;;
    esac ;;
  rbac)
    case $TYPE in
      admin|developer|read-only|readonly|1|2|3)
        path="rbac/argocd-rbac-cm.yaml"
        ;;
      *) error "Invalid RBAC type (expected admin/developer/read-only)"; exit 1 ;;
    esac ;;
  notify|notifications)
    case $TYPE in
      slack|1) path="notifications/slack-secret.yaml" ;;
      email|2) path="notifications/email-secret.yaml" ;;
      webhook|3) path="notifications/webhook-secret.yaml" ;;
      *) error "Invalid notification type"; exit 1 ;;
    esac ;;
  *)
    error "❌ Invalid mode. Must be one of: app, project, rbac, notify."
    exit 1 ;;
esac

# --- Fetch Template Function ---
fetch_template() {
  local rel="$1" dest="$2" cache="$CACHE_DIR/$(basename "$rel")"
  if [ "$ONLINE" = true ]; then
    if curl -sf --retry 3 --retry-delay 2 "$REPO_URL/$rel" -o "$dest"; then
      cp "$dest" "$cache" >/dev/null 2>&1
      success "✅ Downloaded template from GitHub"
      return 0
    fi
  fi
  [ -f "$cache" ] && cp "$cache" "$dest" && success "📦 Using cached template" && return 0
  [ -f "$rel" ] && cp "$rel" "$dest" && warn "📂 Using local fallback" && return 0
  error "❌ Template not found"; return 1
}

TEMPLATE="$DEST_DIR/template.yaml"
fetch_template "$path" "$TEMPLATE" || exit 1

# --- Replace Placeholders ---
sed -i \
  -e "s/{{APP_NAME}}/$APP/g" \
  -e "s/{{NAMESPACE}}/$NS/g" \
  -e "s|{{REPO_URL}}|$GITREPO|g" \
  -e "s/{{BRANCH}}/$BRANCH/g" \
  -e "s/{{PROJECT}}/$PROJECT/g" "$TEMPLATE"

# --- Output Naming (No Overwrite) ---
case $MODE in
  app) OUTPUT_FILE="${APP}-argocd.yaml" ;;
  project) OUTPUT_FILE="${APP}-project.yaml" ;;
  rbac) OUTPUT_FILE="${APP}-rbac.yaml" ;;
  notify|notifications) OUTPUT_FILE="${APP}-notify.yaml" ;;
  *) OUTPUT_FILE="${APP}-template.yaml" ;;
esac

# Ensure unique file if already exists
if [ -f "$DEST_DIR/$OUTPUT_FILE" ]; then
  timestamped="${APP}-$(date +%H%M%S)-${MODE}.yaml"
  warn "⚠️ File already exists, saving as: $timestamped"
  OUTPUT_FILE="$timestamped"
fi

mv "$TEMPLATE" "$DEST_DIR/$OUTPUT_FILE"

# --- Addons ---
if [ -z "$ADDONS_FLAGS" ]; then
  echo "--------------------------------------------"
  echo "Optional Addons:"
  echo "1) Auto Sync"
  echo "2) Resource Prune"
  echo "3) Image Updater"
  echo "4) GPG Verification"
  read_input addons "Select addons (comma-separated or Enter to skip)" ""
else
  addons="$ADDONS_FLAGS"
fi

IFS=',' read -ra ADDONS <<< "$addons"
for addon in "${ADDONS[@]}"; do
  case ${addon// /} in
    1) addon_file="auto-sync.yaml" ;;
    2) addon_file="resource-prune.yaml" ;;
    3) addon_file="image-updater.yaml" ;;
    4) addon_file="gpg-verify.yaml" ;;
    *) continue ;;
  esac

  info "📦 Adding addon: $addon_file"
  cache_file="$CACHE_DIR/$addon_file"
  if [ "$ONLINE" = true ] && curl -sf "$REPO_URL/addons/$addon_file" -o "$DEST_DIR/$addon_file"; then
    cp "$DEST_DIR/$addon_file" "$cache_file" >/dev/null 2>&1
    success "✅ Added from GitHub"
  fi
done

# --- Ask to attach addons ---
if [ $# -eq 0 ] && [ -z "$ATTACH_ADDONS" ]; then
  echo "--------------------------------------------"
  read_input ATTACH_ADDONS "Attach selected addons directly into ${OUTPUT_FILE}? (true/false)" "$DEFAULT_ATTACH"
fi

# --- Injection Function ---
inject_under_spec() {
  local target="$1" snippet="$2"
  if grep -q '^spec:' "$target"; then
    if grep -q '^[[:space:]]\{2\}syncPolicy:' "$target"; then
      warn "ℹ️ syncPolicy already present — skipping $(basename "$snippet")"
      return 0
    fi
    awk -v INS="$(sed 's/\\/\\\\/g;s/\"/\\"/g' "$snippet")" '
      BEGIN{printed=0}
      /^spec:/ && !printed {
        print;
        n=split(INS, L, "\n");
        for(i=1;i<=n;i++){ if(L[i]!="") printf("  %s\n", L[i]); }
        printed=1; next
      } { print }
    ' "$target" > "$target.tmp" && mv "$target.tmp" "$target"
    success "✅ Injected $(basename "$snippet")"
  else
    warn "⚠️ spec: not found — appending snippet."
    echo -e "\n---\n" >> "$target"; cat "$snippet" >> "$target"
  fi
}

# --- Attach Addons if true ---
if [[ "$ATTACH_ADDONS" =~ ^[Tt]rue$ ]]; then
  info "🔗 Attaching selected addons directly into ${OUTPUT_FILE} ..."
  for addon in "${ADDONS[@]}"; do
    case ${addon// /} in
      1) inject_under_spec "$DEST_DIR/$OUTPUT_FILE" "$DEST_DIR/auto-sync.yaml" ;;
      2) inject_under_spec "$DEST_DIR/$OUTPUT_FILE" "$DEST_DIR/resource-prune.yaml" ;;
      3) info "ℹ️ Image Updater annotations already injected." ;;
      4) [ -f "$DEST_DIR/gpg-verify.yaml" ] && echo -e "\n---\n" >> "$DEST_DIR/$OUTPUT_FILE" && cat "$DEST_DIR/gpg-verify.yaml" >> "$DEST_DIR/$OUTPUT_FILE" && success "✅ GPG Verify appended" ;;
    esac
  done
  success "✅ Addons attached to ${OUTPUT_FILE}"
else
  info "ℹ️ Attachment disabled (use --attach-addons true to enable)."
fi

# --- Cleanup ---
find "$DEST_DIR" -name "tmpfile" -type f -delete 2>/dev/null
success "✅ Argo CD templates generated in: $DEST_DIR"
( command -v tree >/dev/null 2>&1 && tree "$DEST_DIR" ) || ls -R "$DEST_DIR"
