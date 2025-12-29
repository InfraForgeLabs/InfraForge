#!/bin/bash
REPO_URL="https://raw.githubusercontent.com/InfraForgeLabs/InfraForge/main/HelmTemplates"
OUT_DIR="${HOME:?HOME is not set}/InfraForge/helm-templates"
CACHE_DIR=".cache/helm-templates"
mkdir -p "$OUT_DIR" "$CACHE_DIR"

# --- Colors & Logging ---
timestamp() { date +"%H:%M:%S"; }
info()    { echo -e "\033[1;34m[$(timestamp)] $1\033[0m"; }
success() { echo -e "\033[1;32m[$(timestamp)] $1\033[0m"; }
warn()    { echo -e "\033[1;33m[$(timestamp)] $1\033[0m"; }
error()   { echo -e "\033[1;31m[$(timestamp)] $1\033[0m"; }

# --- Read helper (Backspace-capable + default fallback) ---
read_input() {
  local varname=$1 prompt=$2 default=$3 value
  read -e -p "$prompt [$default]: " value
  [[ -z "$value" ]] && value="$default"
  printf -v "$varname" '%s' "$value"
}

# --- CLI Flags ---
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --mode) MODE="$2"; shift ;;
    --chart) CHART="$2"; shift ;;
    --app) APP="$2"; shift ;;
    --ns|--namespace) NS="$2"; shift ;;
    --image) IMAGE="$2"; shift ;;
    --replicas) REPLICAS="$2"; shift ;;
    --port) PORT="$2"; shift ;;
    --addons) ADDONS_FLAGS="$2"; shift ;;
    --extras) EXTRAS_FLAGS="$2"; shift ;;
    --hardened) HARDENED="true" ;;
    --help|-h)
      echo "============================================================"
      echo "⚓ Universal Helm Chart Generator v2.5 — Help & Usage Guide"
      echo "============================================================"
      echo ""
      echo "USAGE:"
      echo "  bash helm-template.sh [options]"
      echo ""
      echo "OPTIONS:"
      echo "  --mode <minimal|production|hardened>     Chart mode"
      echo "  --chart <chart-name>                     Helm chart name"
      echo "  --app <app-name>                         Application name"
      echo "  --ns <namespace>                         Kubernetes namespace"
      echo "  --image <image:tag>                      Docker image"
      echo "  --replicas <num>                         Replica count"
      echo "  --port <port>                            Service port"
      echo "  --extras <1,2,3>                         Enable optional features (Resources/Probes/Env)"
      echo "  --addons <1,5,9>                         Add hardened addons (1=NetworkPolicy, etc.)"
      echo "  --hardened                               Enable full hardened mode"
      echo ""
      exit 0 ;;
    *) warn "⚠️ Unknown flag: $1" ;;
  esac
  shift
done

# --- Defaults ---
DEFAULT_MODE="minimal"
DEFAULT_CHART="my-chart"
DEFAULT_APP="my-app"
DEFAULT_NS="default"
DEFAULT_IMAGE="nginx:latest"
DEFAULT_REPLICAS="1"
DEFAULT_PORT="80"
ADDONS_FLAGS=""
EXTRAS_FLAGS=""
addons=""
extras=""

MODE=${MODE:-$DEFAULT_MODE}
CHART=${CHART:-$DEFAULT_CHART}
APP=${APP:-$DEFAULT_APP}
NS=${NS:-$DEFAULT_NS}
IMAGE=${IMAGE:-$DEFAULT_IMAGE}
REPLICAS=${REPLICAS:-$DEFAULT_REPLICAS}
PORT=${PORT:-$DEFAULT_PORT}

# --- Online Detection ---
CHECK_URL="$REPO_URL/production/Chart.yaml"
if curl -sfI "$CHECK_URL" >/dev/null 2>&1; then
  ONLINE=true
  success "🌐 Online mode detected — templates will be fetched from GitHub."
else
  ONLINE=false
  warn "⚠️ Offline mode — using cached or local templates."
fi

# --- Interactive if no flags ---
if [ $# -eq 0 ]; then
  echo ""
  info "💡 Tip: Run 'bash helm-template.sh --help' for automation flags & examples."
  echo ""
  echo "============================================"
  info "⚓ Universal Helm Chart Generator v2.5"
  echo "============================================"
  echo "Modes:"
  echo "1) Minimal (Dev/Test)"
  echo "2) Production (Live)"
  echo "3) Hardened (Prod + Addons)"
  read_input mode "Select mode [1-3]" "1"
  case $mode in
    1) MODE_PATH="minimal" ;;
    2) MODE_PATH="production" ;;
    3) MODE_PATH="production"; HARDENED="true" ;;
  esac

  read_input CHART "Enter chart name" "$DEFAULT_CHART"
  read_input APP "Enter application name" "$DEFAULT_APP"
  read_input NS "Enter namespace" "$DEFAULT_NS"
  read_input IMAGE "Enter image" "$DEFAULT_IMAGE"
  read_input REPLICAS "Enter replicas" "$DEFAULT_REPLICAS"
  read_input PORT "Enter service port" "$DEFAULT_PORT"
else
  case $MODE in
    minimal|1) MODE_PATH="minimal" ;;
    production|2) MODE_PATH="production" ;;
    hardened|3) MODE_PATH="production"; HARDENED="true" ;;
    *) error "Invalid mode: $MODE"; exit 1 ;;
  esac
fi

# --- Set Paths ---
CHART_DIR="$OUT_DIR/$CHART"
mkdir -p "$CHART_DIR/templates"

# --- Fetch Template Function ---
fetch_template() {
  local rel="$1"
  local dest="$2"
  local cache="$CACHE_DIR/$rel"
  mkdir -p "$(dirname "$cache")"
  mkdir -p "$(dirname "$dest")"

  if [ "$ONLINE" = true ] && curl -sf --retry 3 --retry-delay 2 "$REPO_URL/$rel" -o "$dest"; then
    cp "$dest" "$cache" >/dev/null 2>&1
    success "✅ Downloaded: $rel"
  elif [ -f "$cache" ]; then
    cp "$cache" "$dest"
    success "📦 Used cached: $(basename "$cache")"
  elif [ -f "$rel" ]; then
    cp "$rel" "$dest"
    warn "📂 Used local fallback: $rel"
  else
    warn "⚠️ Missing: $rel"
  fi
}

# --- Core Files ---
FILES=( "Chart.yaml" "values.yaml" "templates/deployment.yaml" "templates/service.yaml" "templates/ingress.yaml" )
for file in "${FILES[@]}"; do
  fetch_template "$MODE_PATH/$file" "$CHART_DIR/$file"
done

# --- Replace Placeholders ---
find "$CHART_DIR" -type f -exec sed -i \
  -e "s/{{CHART_NAME}}/$CHART/g" \
  -e "s/{{APP_NAME}}/$APP/g" \
  -e "s/{{NAMESPACE}}/$NS/g" \
  -e "s/{{IMAGE}}/$IMAGE/g" \
  -e "s/{{REPLICAS}}/$REPLICAS/g" \
  -e "s/{{PORT}}/$PORT/g" {} +

# --- Optional Features ---
INCLUDE_RESOURCES=false
INCLUDE_PROBES=false
INCLUDE_ENV=false

if [ -n "$EXTRAS_FLAGS" ]; then
  IFS=',' read -ra EXTRAS <<< "$EXTRAS_FLAGS"
else
  echo "--------------------------------------------"
  echo "Optional Features:"
  echo "1) Add Resource Limits"
  echo "2) Add Liveness/Readiness Probes"
  echo "3) Add Environment Variables"
  read_input extras "Select optional features (comma-separated or press Enter to skip)" ""
  IFS=',' read -ra EXTRAS <<< "$extras"
fi

for e in "${EXTRAS[@]}"; do
  case ${e// /} in
    1) INCLUDE_RESOURCES=true ;;
    2) INCLUDE_PROBES=true ;;
    3) INCLUDE_ENV=true ;;
  esac
done

# --- Append to values.yaml ---
{
  if [ "$INCLUDE_RESOURCES" = true ]; then
    cat <<EOF

resources:
  limits:
    cpu: 200m
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 256Mi
EOF
  fi

  if [ "$INCLUDE_PROBES" = true ]; then
    cat <<EOF

probes:
  liveness:
    path: /
    port: $PORT
  readiness:
    path: /
    port: $PORT
EOF
  fi

  if [ "$INCLUDE_ENV" = true ]; then
    cat <<EOF

env:
  - name: ENV
    value: production
EOF
  fi
} >> "$CHART_DIR/values.yaml"

DEPLOY_FILE="$CHART_DIR/templates/deployment.yaml"
if [ "$INCLUDE_ENV" = true ]; then
  sed -i "/containerPort: $PORT/a\          env:\n            - name: ENV\n              value: production" "$DEPLOY_FILE"
fi
if [ "$INCLUDE_PROBES" = true ]; then
  sed -i "/containerPort: $PORT/a\          readinessProbe:\n            httpGet:\n              path: /\n              port: $PORT\n          livenessProbe:\n            httpGet:\n              path: /\n              port: $PORT" "$DEPLOY_FILE"
fi
if [ "$INCLUDE_RESOURCES" = true ]; then
  sed -i "/containerPort: $PORT/a\          resources:\n            limits:\n              cpu: 200m\n              memory: 512Mi\n            requests:\n              cpu: 100m\n              memory: 256Mi" "$DEPLOY_FILE"
fi

# --- Hardened Addons ---
if [ "$HARDENED" = "true" ]; then
  if [ -z "$ADDONS_FLAGS" ]; then
    echo "--------------------------------------------"
    echo "🧱 Available Addons:"
    echo "1) NetworkPolicy  2) ServiceMonitor  3) ResourceQuota"
    echo "4) TLS Secret      5) ServiceAccount  6) Role"
    echo "7) RoleBinding     8) PDB             9) HPA"
    echo "10) ConfigMap      11) Secret         12) Cleanup Job"
    echo "13) CronJob        14) Alerts         15) Dashboard"
    echo "16) VirtualService 17) Gateway        18) ServiceEntry"
    echo "19) DB Migration Hook"
    read_input addons "Select addons (comma-separated or Enter to skip)" ""
  else
    addons="$ADDONS_FLAGS"
  fi

  declare -A ADDON_MAP=(
    [1]="networkpolicy.yaml"
    [2]="servicemonitor.yaml"
    [3]="resourcequota.yaml"
    [4]="tls-secret.yaml"
    [5]="serviceaccount.yaml"
    [6]="role.yaml"
    [7]="rolebinding.yaml"
    [8]="pdb.yaml"
    [9]="hpa.yaml"
    [10]="configmap.yaml"
    [11]="secret.yaml"
    [12]="cleanup-hook.yaml"
    [13]="cronjob.yaml"
    [14]="alerts.yaml"
    [15]="dashboard-configmap.yaml"
    [16]="istio-virtualservice.yaml"
    [17]="gateway.yaml"
    [18]="service-entry.yaml"
    [19]="hooks-job-migrate.yaml"
  )

  IFS=',' read -ra ADDONS <<< "$addons"
  for addon in "${ADDONS[@]}"; do
    addon_clean=$(echo "$addon" | tr -d ' ')
    addon_path="${ADDON_MAP[$addon_clean]}"
    [ -z "$addon_path" ] && continue

    info "📦 Adding addon: $addon_path"
    CACHE_FILE="$CACHE_DIR/$addon_path"

    if [ "$ONLINE" = true ] && curl -sf "$REPO_URL/addons/$addon_path" -o "$CHART_DIR/templates/$addon_path"; then
      cp "$CHART_DIR/templates/$addon_path" "$CACHE_FILE" >/dev/null 2>&1
      success "✅ Added from GitHub"
    elif [ -f "$CACHE_FILE" ]; then
      cp "$CACHE_FILE" "$CHART_DIR/templates/$addon_path"
      success "📦 Added from cache"
    elif [ -f "addons/$addon_path" ]; then
      cp "addons/$addon_path" "$CHART_DIR/templates/$addon_path"
      warn "📂 Added local fallback"
    fi
  done
fi

# --- Done ---
success "✅ Helm chart created successfully: $CHART_DIR"
( command -v tree >/dev/null 2>&1 && tree "$CHART_DIR" ) || ls -R "$CHART_DIR"
