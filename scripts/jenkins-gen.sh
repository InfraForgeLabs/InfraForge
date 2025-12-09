#!/bin/bash
REPO_URL="https://raw.githubusercontent.com/InfraForgeLabs/InfraForge/main/JenkinsTemplates"
OUT_DIR="generated"
ADDON_DIR="$OUT_DIR/addons"
CACHE_DIR=".cache/jenkins-templates"
mkdir -p "$OUT_DIR" "$CACHE_DIR" "$ADDON_DIR"

# --- Colors & Logging ---
timestamp() { date +"%H:%M:%S"; }
info()    { echo -e "\033[1;34m[$(timestamp)] $1\033[0m"; }
success() { echo -e "\033[1;32m[$(timestamp)] $1\033[0m"; }
warn()    { echo -e "\033[1;33m[$(timestamp)] $1\033[0m"; }
error()   { echo -e "\033[1;31m[$(timestamp)] $1\033[0m"; }

# --- CLI Arguments ---
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --mode) MODE="$2"; shift ;;
    --app) APP="$2"; shift ;;
    --env) ENV="$2"; shift ;;
    --image) IMAGE="$2"; shift ;;
    --repo) REPO="$2"; shift ;;
    --branch) BRANCH="$2"; shift ;;
    --semver) SEMVER="$2"; shift ;;
    --version) BASE_VERSION="$2"; shift ;;
    --addons) ADDONS_FLAGS="$2"; shift ;;
    --help|-h)
      echo "============================================================"
      echo "🧱 Jenkins Pipeline Generator v3.7 — Help & Usage Guide"
      echo "============================================================"
      echo ""
      echo "USAGE:"
      echo "  bash jen.sh [options]"
      echo ""
      echo "OPTIONS:"
      echo "  --mode <minimal|production|hardened>   Select pipeline mode"
      echo "  --app <app-name>                       Application name"
      echo "  --env <environment>                    Environment (dev/staging/prod)"
      echo "  --image <image:tag>                    Docker image"
      echo "  --repo <git-url>                       Git repository URL"
      echo "  --branch <branch>                      Git branch"
      echo "  --semver <true|false>                  Enable semantic versioning"
      echo "  --version <x.y.z>                      Base version"
      echo "  --addons <1,2,3>                       Addon IDs (Slack, Email, Sonar, Trivy, ZAP)"
      echo ""
      exit 0 ;;
    *) warn "⚠️ Unknown flag: $1";;
  esac; shift
done

# --- Defaults ---
DEFAULT_MODE="minimal"
DEFAULT_APP="my-app"
DEFAULT_ENV="dev"
DEFAULT_IMAGE="nginx:latest"
DEFAULT_REPO="git@github.com:example/repo.git"
DEFAULT_BRANCH="main"
DEFAULT_SEMVER="false"
DEFAULT_VERSION="1.0.0"

# --- Read helper ---
read_input() {
  local varname=$1; local prompt=$2; local default=$3; local value
  read -e -p "$prompt [$default]: " value
  eval $varname="'${value:-$default}'"
}

# --- Mode Selection ---
if [[ -z "$MODE" ]]; then
  echo "============================================"
  info "🧱 Jenkins Pipeline Generator v3.7"
  echo "============================================"
  echo "Select pipeline mode:"
  echo "1) Minimal (Build + Deploy)"
  echo "2) Production (Full CI/CD)"
  echo "3) Hardened (DevSecOps)"
  read -e -p "Select mode [1-3] [1]: " mode
  mode=${mode:-1}
else
  case $MODE in
    minimal|1) mode=1 ;;
    production|2) mode=2 ;;
    hardened|3) mode=3 ;;
    *) error "❌ Invalid mode: $MODE"; exit 1 ;;
  esac
fi

case $mode in
  1) MODE_PATH="minimal" ;;
  2) MODE_PATH="production" ;;
  3) MODE_PATH="hardened" ;;
esac

# --- Interactive Input ---
read_input APP "Enter application name" "${APP:-$DEFAULT_APP}"
read_input ENV "Enter environment" "${ENV:-$DEFAULT_ENV}"
read_input IMAGE "Enter Docker image" "${IMAGE:-$DEFAULT_IMAGE}"
read_input REPO "Enter Git repository URL" "${REPO:-$DEFAULT_REPO}"
read_input BRANCH "Enter Git branch" "${BRANCH:-$DEFAULT_BRANCH}"
read_input SEMVER "Enable semantic versioning (true/false)" "${SEMVER:-$DEFAULT_SEMVER}"
read_input BASE_VERSION "Enter base semantic version" "${BASE_VERSION:-$DEFAULT_VERSION}"

# --- Online Check ---
CHECK_URL="$REPO_URL/production/Jenkinsfile"
if curl -sfI "$CHECK_URL" >/dev/null 2>&1; then
  ONLINE=true; success "🌐 Online mode — templates will be fetched from GitHub."
else
  ONLINE=false; warn "⚠️ Offline mode — using cached or local templates."
fi

# --- Version Tag ---
if [[ "$SEMVER" =~ ^[Tt]rue$ ]]; then
  version_tag="${BASE_VERSION}"
else
  version_tag="v$(date +%Y.%m.%d.%H%M)"
fi
info "🔖 Using version tag: ${version_tag}"

DEST_FILE="$OUT_DIR/Jenkinsfile-$APP"
CACHE_FILE="$CACHE_DIR/${MODE_PATH}-Jenkinsfile"

# --- Fetch Template ---
fetch_template() {
  local rel="$1"; local dest="$2"; local cache="$3"
  if [ "$ONLINE" = true ] && curl -sf --retry 3 --retry-delay 2 "$REPO_URL/$rel" -o "$dest"; then
    cp "$dest" "$cache" >/dev/null 2>&1; success "✅ Downloaded Jenkinsfile from GitHub"
  elif [ -f "$cache" ]; then
    cp "$cache" "$dest"; success "📦 Using cached Jenkinsfile"
  elif [ -f "$rel" ]; then
    cp "$rel" "$dest"; warn "📂 Using local Jenkinsfile"
  else
    error "❌ Template not found (online, cache, or local)"; return 1
  fi
}
fetch_template "$MODE_PATH/Jenkinsfile" "$DEST_FILE" "$CACHE_FILE" || exit 1

# --- Replace Placeholders ---
sed -i \
  -e "s/{{APP_NAME}}/$APP/g" \
  -e "s/{{ENV}}/$ENV/g" \
  -e "s/{{IMAGE}}/$IMAGE/g" \
  -e "s|{{REPO_URL}}|$REPO|g" \
  -e "s/{{BRANCH}}/$BRANCH/g" \
  -e "s/{{VERSION_TAG}}/$version_tag/g" "$DEST_FILE"

# --- Addons (Production + Hardened) ---
if [[ "$MODE_PATH" == "production" || "$MODE_PATH" == "hardened" ]]; then
  echo "--------------------------------------------"
  echo "Add Security & Notification Addons:"
  echo "1) Slack Notification"
  echo "2) Email Notification"
  echo "3) SonarQube Stage"
  echo "4) Trivy Scan"
  echo "5) ZAP Scan"
  read -e -p "Select addons (comma-separated or press Enter to skip) []: " addons
  addons=${addons:-$ADDONS_FLAGS}

  IFS=',' read -ra ADDONS <<< "$addons"
  for addon in "${ADDONS[@]}"; do
    addon_trimmed=$(echo "$addon" | xargs)
    case $addon_trimmed in
      1) addon_file="slack-notify.groovy" ;;
      2) addon_file="email-notify.groovy" ;;
      3) addon_file="sonar-stage.groovy" ;;
      4) addon_file="trivy-stage.groovy" ;;
      5) addon_file="zap-stage.groovy" ;;
      *) warn "⚠️ Unknown addon selection: $addon_trimmed"; continue ;;
    esac

    info "📦 Fetching addon: $addon_file"
    CACHE_ADDON="$CACHE_DIR/$addon_file"
    DEST_ADDON="$ADDON_DIR/$addon_file"

    if [ "$ONLINE" = true ] && curl -sf --retry 3 --retry-delay 2 "$REPO_URL/addons/$addon_file" -o "$DEST_ADDON"; then
      cp "$DEST_ADDON" "$CACHE_ADDON"
      success "✅ Saved $addon_file in generated/addons/"
    elif [ -f "$CACHE_ADDON" ]; then
      cp "$CACHE_ADDON" "$DEST_ADDON"
      success "📦 Restored $addon_file from cache"
    elif [ -f "addons/$addon_file" ]; then
      cp "addons/$addon_file" "$DEST_ADDON"
      warn "📂 Copied local fallback for $addon_file"
    else
      warn "⚠️ Skipped missing addon $addon_file"
      continue
    fi

    # --- Add Header Comment for user guidance ---
    sed -i "1i\\
    // ============================================================\\n// 📎 Addon: ${addon_file}\\n// ------------------------------------------------------------\\n// 💡 To use: copy this stage into your Jenkinsfile where needed.\\n// Example:\\n//     stage('Security Scan') { ... }\\n// ============================================================\\n" "$DEST_ADDON"

  done

  success "🧩 All selected addons are available in: $ADDON_DIR/"
  echo ""
  info "👉 You can manually include these snippets inside Jenkinsfile as needed."
fi

# --- Completion ---
success "✅ Jenkinsfile generated successfully: $DEST_FILE"
head -n 20 "$DEST_FILE" && echo "..."
