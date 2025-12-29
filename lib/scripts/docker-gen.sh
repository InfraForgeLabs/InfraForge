#!/bin/bash
REPO_URL="https://raw.githubusercontent.com/InfraForgeLabs/InfraForge/main/DockerTemplates"
OUT_DIR="${HOME:?HOME is not set}/Infraforge/docker-templates"
CACHE_DIR=".cache/docker-templates"
mkdir -p "$OUT_DIR" "$CACHE_DIR" "$OUT_DIR/addons"

# --- Colors & Logging ---
timestamp() { date +"%H:%M:%S"; }
info()    { echo -e "\033[1;34m[$(timestamp)] $1\033[0m"; }
success() { echo -e "\033[1;32m[$(timestamp)] $1\033[0m"; }
warn()    { echo -e "\033[1;33m[$(timestamp)] $1\033[0m"; }
error()   { echo -e "\033[1;31m[$(timestamp)] $1\033[0m"; }

ADDONS_FLAGS=""
addons=""

# --- Backspace-Capable Input ---
read_input() {
  local varname=$1 prompt=$2 default=$3 value
  read -e -p "$prompt [$default]: " value
  [[ -z "$value" ]] && value="$default"
  printf -v "$varname" '%s' "$value"
}

# --- CLI Args ---
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --mode) MODE="$2"; shift ;;
    --stack) STACK="$2"; shift ;;
    --app) APP="$2"; shift ;;
    --port) PORT="$2"; shift ;;
    --semver) SEMVER="$2"; shift ;;
    --version) BASE_VERSION="$2"; shift ;;
    --addons) ADDONS_FLAGS="$2"; shift ;;
    --services) SERVICES="$2"; shift ;;
    --vars) VARS="$2"; shift ;;
    --help|-h)
      echo "============================================================"
      echo "🐳 Docker Template Generator v5.3 — Help & Usage Guide"
      echo "============================================================"
      echo ""
      echo "USAGE:"
      echo "  bash docker-template.sh [options]"
      echo ""
      echo "OPTIONS:"
      echo "  --mode <minimal|production|compose>     Select template mode"
      echo "  --stack <python|node|golang|ruby|php>   Language stack (for Dockerfile modes)"
      echo "  --app <app-name>                        Application name"
      echo "  --port <port>                           Exposed port (default 8080)"
      echo "  --semver <true|false>                   Enable semantic version tagging"
      echo "  --version <x.y.z>                       Base version if semver enabled"
      echo "  --addons <1,2,3>                        Add optional addons"
      echo "  --services <count>                      For compose mode: number of services"
      echo "  --vars <key=value,...>                  Custom vars for placeholders"
      echo ""
      echo "EXAMPLES:"
      echo "  bash docker-template.sh --mode minimal --stack node --app api"
      echo "  bash docker-template.sh --mode production --stack python --semver true --version 2.1.0"
      echo "  bash docker-template.sh --mode compose --services 3 --app webapp"
      echo ""
      exit 0 ;;
    *) warn "⚠️ Unknown flag: $1" ;;
  esac
  shift
done

# --- Defaults ---
DEFAULT_MODE="minimal"
DEFAULT_STACK="python"
DEFAULT_APP="my-app"
DEFAULT_PORT="8080"
DEFAULT_SEMVER="false"
DEFAULT_BASE_VERSION="1.0.0"

MODE=${MODE:-$DEFAULT_MODE}
STACK=${STACK:-$DEFAULT_STACK}
APP=${APP:-$DEFAULT_APP}
PORT=${PORT:-$DEFAULT_PORT}
SEMVER=${SEMVER:-$DEFAULT_SEMVER}
BASE_VERSION=${BASE_VERSION:-$DEFAULT_BASE_VERSION}

# --- Parse Vars ---
if [[ -n "${VARS:-}" ]]; then
  IFS=',' read -ra VAR_ARRAY <<< "$VARS"
  for v in "${VAR_ARRAY[@]}"; do
    key="${v%%=*}"
    value="${v#*=}"
    if [[ "$key" =~ ^[A-Z_][A-Z0-9_]*$ ]]; then
      printf -v "$key" '%s' "$value"
    else
      warn "⚠️ Invalid variable ignored: $key"
    fi
  done
fi

# --- Online Check ---
CHECK_URL="$REPO_URL/minimal/python/Dockerfile"
if curl -sfI "$CHECK_URL" >/dev/null 2>&1; then
  ONLINE=true; success "🌐 Online mode detected — templates will be fetched from GitHub."
else
  ONLINE=false; warn "⚠️ Offline mode — using cached or local templates."
fi

# --- Interactive if No Args ---
if [ $# -eq 0 ]; then
  echo ""
  info "💡 Tip: Run 'bash docker-template.sh --help' for automation flags & examples."
  echo ""
  echo "============================================"
  info " 🐳 Docker Template Generator v5.3 "
  echo "============================================"
  echo "Modes:"
  echo "1) Minimal"
  echo "2) Production"
  echo "3) Compose"
  read_input mode "Select mode [1-3]" "1"

  case $mode in
    1) MODE="minimal" ;;
    2) MODE="production" ;;
    3) MODE="compose" ;;
  esac

  read_input STACK "Select stack (python/node/golang/ruby/php)" "$DEFAULT_STACK"
  read_input APP "Enter application name" "$DEFAULT_APP"
  read_input PORT "Enter exposed port" "$DEFAULT_PORT"
  read_input SEMVER "Enable semantic versioning (true/false)" "$DEFAULT_SEMVER"
  read_input BASE_VERSION "Enter base version if semver enabled" "$DEFAULT_BASE_VERSION"
  if [[ "$MODE" == "compose" ]]; then
    read_input SERVICES "Enter number of services" "2"
  fi
fi

# --- Version Tag ---
if [[ "$SEMVER" =~ ^[Tt]rue$ ]]; then
  IMAGE_TAG="v${BASE_VERSION}"
else
  IMAGE_TAG="v$(date +%Y.%m.%d.%H%M)"
fi
info "🔖 Using Docker image tag: ${IMAGE_TAG}"

# ============================================================
# 🧩 Compose Mode
# ============================================================
if [[ "$MODE" == "compose" ]]; then
  app="$APP"
  DEST="$OUT_DIR/docker-compose.yaml"
  svc_count=${SERVICES:-0}

  if (( svc_count == 0 )); then
    info "⚙️ Using fallback multi-service template..."
    TEMPLATE_URL="$REPO_URL/compose/multi-service.yaml"
    CACHE_FILE="$CACHE_DIR/multi-service.yaml"
    if [ "$ONLINE" = true ] && curl -sf --retry 3 --retry-delay 2 "$TEMPLATE_URL" -o "$DEST"; then
      cp "$DEST" "$CACHE_FILE" >/dev/null 2>&1; success "✅ Downloaded fallback from GitHub"
    elif [ -f "$CACHE_FILE" ]; then
      cp "$CACHE_FILE" "$DEST"; success "📦 Used cached fallback template"
    elif [ -f "compose/multi-service.yaml" ]; then
      cp "compose/multi-service.yaml" "$DEST"; warn "📂 Used local fallback template"
    else
      error "❌ No fallback multi-service.yaml found"; exit 1
    fi
  else
    echo "version: \"3.8\"" > "$DEST"
    echo "" >> "$DEST"
    echo "services:" >> "$DEST"
    for (( i=1; i<=svc_count; i++ )); do
      sname="service$i"
      echo "  $sname:" >> "$DEST"
      echo "    build: ./$sname" >> "$DEST"
      echo "    container_name: ${app}_${sname}" >> "$DEST"
      echo "    restart: unless-stopped" >> "$DEST"
      echo "" >> "$DEST"
    done
  fi

  sed -i "s/{{APP_NAME}}/$app/g" "$DEST"
  sed -i "s/{{IMAGE_TAG}}/$IMAGE_TAG/g" "$DEST"
  sed -i "s/{{PORT_API}}/${PORT}/g" "$DEST"
  sed -i "s/{{PORT_FRONTEND}}/3000/g" "$DEST"
  success "✅ docker-compose.yaml ready: $DEST"
fi

# ============================================================
# 🐋 Dockerfile Mode (Minimal / Production)
# ============================================================
case $STACK in
  python) base="python:3.12-slim"; install="pip install -r requirements.txt"; run='["python", "app.py"]';;
  node) base="node:20-alpine"; install="npm install"; run='["npm", "start"]' ;;
  golang) base="golang:1.22"; install="go mod tidy"; run='["./app"]' ;;
  ruby) base="ruby:3.3"; install="bundle install"; run='["ruby", "app.rb"]' ;;
  php) base="php:8.3-apache"; install="composer install"; run='["apache2-foreground"]' ;;
  *) error "Invalid stack"; exit 1 ;;
esac

MODE_DIR="$([[ "$MODE" == "minimal" ]] && echo "minimal" || echo "production")"
TEMPLATE_PATH="$MODE_DIR/$STACK/Dockerfile"
CACHE_FILE="$CACHE_DIR/${MODE_DIR}-${STACK}.Dockerfile"
OUTPUT_FILE="$OUT_DIR/${APP}-Dockerfile"
TMP_FILE="$OUT_DIR/template.Dockerfile"

fetch_template() {
  local rel="$1" dest="$2" cache="$3"
  if [ "$ONLINE" = true ] && curl -sf --retry 3 --retry-delay 2 "$REPO_URL/$rel" -o "$dest"; then
    cp "$dest" "$cache" >/dev/null 2>&1; success "✅ Downloaded from GitHub"
  elif [ -f "$cache" ]; then
    cp "$cache" "$dest"; success "📦 Using cached template"
  elif [ -f "$rel" ]; then
    cp "$rel" "$dest"; warn "📂 Using local fallback"
  else
    error "❌ Template not found (online, cache, or local)"
    return 1
  fi
}

info "📥 Fetching template: $TEMPLATE_PATH ..."
if ! fetch_template "$TEMPLATE_PATH" "$TMP_FILE" "$CACHE_FILE"; then
  exit 1
fi

escape_sed() { echo "$1" | sed -e 's/[\/&]/\\&/g'; }
base_esc=$(escape_sed "$base"); install_esc=$(escape_sed "$install"); run_esc=$(escape_sed "$run")
port_esc=$(escape_sed "$PORT"); tag_esc=$(escape_sed "$IMAGE_TAG")

sed -e "s|{{BASE_IMAGE}}|$base_esc|g" \
    -e "s|{{INSTALL_CMD}}|$install_esc|g" \
    -e "s|{{RUN_CMD}}|$run_esc|g" \
    -e "s|{{PORT}}|$port_esc|g" \
    -e "s|{{IMAGE_TAG}}|$tag_esc|g" \
    "$TMP_FILE" > "$OUTPUT_FILE"

rm -f "$TMP_FILE"
success "✅ Dockerfile ready: $OUTPUT_FILE"

# ============================================================
# 🧩 Addons for all modes
# ============================================================
if [ -z "$ADDONS_FLAGS" ]; then
  echo "--------------------------------------------"
  echo "Available Add-ons:"
  echo "1) Healthcheck"
  echo "2) Logging"
  echo "3) Networks"
  echo "4) Volumes"
  echo "5) Env Template"
  read_input addons "Select addons (comma-separated or press Enter to skip)" ""
else
  addons="$ADDONS_FLAGS"
fi

IFS=',' read -ra ADDONS <<< "$addons"
for addon in "${ADDONS[@]}"; do
  case ${addon// /} in
    1) addon_file="healthcheck.yaml" ;;
    2) addon_file="logging.yaml" ;;
    3) addon_file="networks.yaml" ;;
    4) addon_file="volumes.yaml" ;;
    5) addon_file="env-template.yaml" ;;
    *) continue ;;
  esac

  info "📦 Fetching addon: $addon_file"
  CACHE_ADDON="$CACHE_DIR/$addon_file"
  ADDON_URL="$REPO_URL/addons/$addon_file"
  DEST_FILE="$OUT_DIR/addons/$addon_file"

  if [ "$ONLINE" = true ] && curl -sf "$ADDON_URL" -o "$DEST_FILE"; then
    sed -i "s/{{APP_NAME}}/$APP/g" "$DEST_FILE"
    sed -i "s/{{IMAGE_TAG}}/$IMAGE_TAG/g" "$DEST_FILE"
    cp "$DEST_FILE" "$CACHE_ADDON" >/dev/null 2>&1
    success "✅ Saved: $DEST_FILE"
  elif [ -f "$CACHE_ADDON" ]; then
    cp "$CACHE_ADDON" "$DEST_FILE"; success "📦 Used cached: $addon_file"
  fi
done

# ============================================================
# 🧩 Dockerfile Addon Snippets (Minimal/Production)
# ============================================================
if [[ "$MODE" != "compose" ]]; then
  echo ""
  info "🧩 Generating Dockerfile addon snippets..."
  ADDON_DIR="$OUT_DIR/addons"
  mkdir -p "$ADDON_DIR"

  for addon in "${ADDONS[@]}"; do
    case ${addon// /} in
      1)
        cat <<EOF > "$ADDON_DIR/healthcheck-snippet.txt"
# 🧩 Healthcheck Addon
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \\
  CMD curl -f http://localhost:${PORT}/health || exit 1
EOF
        success "✅ Added Dockerfile healthcheck snippet"
        ;;
      2)
        cat <<EOF > "$ADDON_DIR/logging-snippet.txt"
# 🧩 Logging Addon
LABEL org.opencontainers.image.title="${APP}"
LABEL org.opencontainers.image.version="${IMAGE_TAG}"
LABEL org.opencontainers.image.vendor="AutoGen DevSecOps"
EOF
        success "✅ Added Dockerfile logging snippet"
        ;;
      5)
        cat <<EOF > "$ADDON_DIR/env-snippet.txt"
# 🧩 Environment Addon
ENV APP_NAME="${APP}"
ENV PORT="${PORT}"
ENV VERSION="${IMAGE_TAG}"
ENV NODE_ENV="production"
EOF
        success "✅ Added Dockerfile env snippet"
        ;;
    esac
  done

  echo ""
  success "✅ Dockerfile addon snippets generated in: $ADDON_DIR"
  info "👉 To use: cat generated/addons/*-snippet.txt >> generated/${APP}-Dockerfile"
  echo ""
fi

success "🎯 All files ready in: $OUT_DIR"
