#!/bin/bash
VERSION="7.8"
REPO_URL="https://raw.githubusercontent.com/InfraForgeLabs/InfraForge/main/K8sYamlTemplates"
SCRIPT_NAME="${HOME:?HOME is not set}/k8s-yaml-gen.sh"
OUT_DIR="InfraForge/k8s-templates"
CACHE_DIR=".cache/k8s-yaml-gen"
mkdir -p "$OUT_DIR" "$CACHE_DIR"

# --- Colors & Logging ---
timestamp() { date +"%H:%M:%S"; }
info()    { echo -e "\033[1;34m[$(timestamp)] $1\033[0m"; }
success() { echo -e "\033[1;32m[$(timestamp)] $1\033[0m"; }
warn()    { echo -e "\033[1;33m[$(timestamp)] $1\033[0m"; }
error()   { echo -e "\033[1;31m[$(timestamp)] $1\033[0m"; }

# --- CLI Arguments ---
CLI_ARGS_COUNT=$#
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --mode) MODE="$2"; shift ;;
    --resource) RESOURCE="$2"; shift ;;
    --app) APP="$2"; shift ;;
    --ns|--namespace) NS="$2"; shift ;;
    --image) IMAGE="$2"; shift ;;
    --port) PORT="$2"; shift ;;
    --replicas) REPLICAS="$2"; shift ;;
    --storage) STORAGE="$2"; shift ;;
    --addons) ADDONS_FLAGS="$2"; shift ;;
    --hardened) HARDENED="true" ;;
    --apply) APPLY="true" ;;
    --dryrun) DRYRUN="true" ;;
    --create-service|--svc) CREATE_SERVICE="true" ;;
    --help|-h)
      echo "============================================================"
      echo "☸️  Kubernetes YAML Generator v${VERSION} — Help"
      echo "============================================================"
      echo "Usage:"
      echo "  bash k8s-yaml-gen.sh [options]"
      echo ""
      echo "Examples:"
      echo "  bash k8s-yaml-gen.sh --mode minimal --resource service --app webapp"
      echo "  bash k8s-yaml-gen.sh --mode production --resource deployment --image nginx:1.25 --replicas 3"
      echo "  bash k8s-yaml-gen.sh --mode hardened --addons 1,3 --app api --resource ingress --apply"
      echo "  bash k8s-yaml-gen.sh --mode production --resource istio --app api --ns prod --port 8080 --create-service"
      exit 0
      ;;
    *) warn "⚠️ Unknown flag: $1" ;;
  esac
  shift
done

# --- Internet Check ---
TEMPLATE_CHECK_URL="$REPO_URL/production/workloads/deployment.yaml"
if curl -sfI "$TEMPLATE_CHECK_URL" >/dev/null 2>&1; then
  ONLINE=true
  success "🌐 Online mode detected — templates will be fetched from GitHub."
else
  ONLINE=false
  warn "⚠️ Offline mode — using local or cached templates."
fi

# --- Defaults ---
DEFAULT_MODE="minimal"
DEFAULT_RESOURCE="deployment"
DEFAULT_APP="my-app"
DEFAULT_NS="default"
DEFAULT_IMAGE="nginx:latest"
DEFAULT_PORT="80"
DEFAULT_REPLICAS="1"
DEFAULT_STORAGE="1Gi"

ADDONS_FLAGS=""
HARDENED="false"
APPLY="false"
DRYRUN="false"
CREATE_SERVICE="false"

MODE=${MODE:-$DEFAULT_MODE}
RESOURCE=${RESOURCE:-$DEFAULT_RESOURCE}
APP=${APP:-$DEFAULT_APP}
NS=${NS:-$DEFAULT_NS}
IMAGE=${IMAGE:-$DEFAULT_IMAGE}
PORT=${PORT:-$DEFAULT_PORT}
REPLICAS=${REPLICAS:-$DEFAULT_REPLICAS}
STORAGE=${STORAGE:-$DEFAULT_STORAGE}

# ============================================================
# 🧙 INTERACTIVE MODE (if no CLI args provided)
# ============================================================
if [[ "$CLI_ARGS_COUNT" -eq 0 && -t 0 ]]; then
  echo ""
  echo "============================================================"
  echo "🧙‍♂️ Kubernetes YAML Generator — Interactive Wizard"
  echo "============================================================"

  echo ""
  echo "Select Mode:"
  echo "1) Minimal"
  echo "2) Production"
  echo "3) Hardened (secure + addons)"
  read -e -p "Select [1-3, default: 1]: " mode_choice
  case $mode_choice in
    2) MODE="production" ;;
    3) MODE="hardened"; HARDENED="true" ;;
    *) MODE="minimal" ;;
  esac

  echo ""
  echo "Select Resource:"
  echo "1) Deployment"
  echo "2) Service"
  echo "3) Ingress"
  echo "4) ConfigMap"
  echo "5) Secret"
  echo "6) PVC"
  echo "7) HPA"
  echo "8) Role / RoleBinding"
  echo "9) Namespace"
  echo "10) Istio (Gateway, VS, DR)"
  read -e -p "Choose [1-10, default: 1]: " res_choice
  case $res_choice in
    2) RESOURCE="service" ;;
    3) RESOURCE="ingress" ;;
    4) RESOURCE="configmap" ;;
    5) RESOURCE="secret" ;;
    6) RESOURCE="pvc" ;;
    7) RESOURCE="hpa" ;;
    8)
      echo "a) Role"
      echo "b) RoleBinding"
      read -e -p "Choose [a/b]: " sub_choice
      [[ "$sub_choice" == "b" ]] && RESOURCE="rolebinding" || RESOURCE="role"
      ;;
    9) RESOURCE="namespace" ;;
    10) RESOURCE="istio" ;;
    *) RESOURCE="deployment" ;;
  esac

  read -e -p "App Name [my-app]: " APP
  APP=${APP:-my-app}
  read -e -p "Namespace [default]: " NS
  NS=${NS:-default}
  read -e -p "Image [nginx:latest]: " IMAGE
  IMAGE=${IMAGE:-nginx:latest}
  read -e -p "Port [80]: " PORT
  PORT=${PORT:-80}
  read -e -p "Replicas [1]: " REPLICAS
  REPLICAS=${REPLICAS:-1}

  if [[ "$RESOURCE" == "pvc" ]]; then
    read -e -p "Storage [1Gi]: " STORAGE
    STORAGE=${STORAGE:-1Gi}
  fi

  if [[ "$HARDENED" == "true" ]]; then
    echo "Available Addons:"
    echo "1) PodDisruptionBudget"
    echo "2) NetworkPolicy"
    echo "3) TLS Ingress"
    echo "4) ResourceQuota"
    echo "5) ServiceMonitor"
    echo "6) Vault SecretProvider"
    echo "7) Istio mTLS"
    read -e -p "Select addons (comma-separated or Enter to skip): " ADDONS_FLAGS
  fi

  echo ""
  echo "✅ Summary:"
  echo "Mode: $MODE | Resource: $RESOURCE | App: $APP | NS: $NS"
  read -e -p "Proceed? (Y/n): " confirm
  [[ "$confirm" =~ ^[Nn]$ ]] && exit 0
fi

# --- Mode Path ---
case $MODE in
  minimal|1) MODE_PATH="minimal" ;;
  production|2) MODE_PATH="production" ;;
  hardened|3) MODE_PATH="production"; HARDENED="true" ;;
  *) MODE_PATH="minimal" ;;
esac

# --- Resource Map ---
declare -A RES_MAP=(
  [deployment]="workloads/deployment.yaml"
  [service]="networking/service.yaml"
  [configmap]="config/configmap.yaml"
  [secret]="config/secret.yaml"
  [ingress]="networking/ingress.yaml"
  [pvc]="storage/pvc.yaml"
  [hpa]="scaling/hpa.yaml"
  [role]="rbac/role.yaml"
  [rolebinding]="rbac/rolebinding.yaml"
  [namespace]="cluster/namespace.yaml"
  [istio]="istio/gateway.yaml"
  [istio-gateway]="istio/gateway.yaml"
  [istio-virtualservice]="istio/virtualservice.yaml"
  [istio-destinationrule]="istio/destinationrule.yaml"
)
path="${RES_MAP[$RESOURCE]}"
suffix="$RESOURCE"

TEMPLATE_PATH="$MODE_PATH/$path"
CACHE_FILE="$CACHE_DIR/${MODE_PATH}-${suffix}.yaml"
OUTPUT_FILE="$OUT_DIR/${APP}-${RESOURCE}.yaml"

info "📥 Using template path: $TEMPLATE_PATH"

# --- Fetch Template ---
fetch_template() {
  local url="$REPO_URL/$TEMPLATE_PATH"
  local target="$OUT_DIR/template.yaml"
  if [ "$ONLINE" = true ] && curl -sf --retry 3 --retry-delay 2 "$url" -o "$target"; then
    success "✅ Template fetched from GitHub"
    cp "$target" "$CACHE_FILE"
  elif [ -f "$CACHE_FILE" ]; then
    cp "$CACHE_FILE" "$target"
    success "📦 Used cached template"
  elif [ -f "$TEMPLATE_PATH" ]; then
    cp "$TEMPLATE_PATH" "$target"
    warn "📂 Used local fallback template"
  else
    error "❌ No template found (online, cached, or local)"
    return 1
  fi
}
fetch_template || exit 1

# --- Replace Placeholders & Generate Final YAML ---
sed -e "s/{{APP_NAME}}/$APP/g" \
    -e "s/{{NAMESPACE}}/$NS/g" \
    -e "s/{{IMAGE}}/$IMAGE/g" \
    -e "s/{{PORT}}/$PORT/g" \
    -e "s/{{REPLICAS}}/$REPLICAS/g" \
    -e "s/{{STORAGE_SIZE}}/$STORAGE/g" \
    "$OUT_DIR/template.yaml" > "$OUTPUT_FILE"

rm -f "$OUT_DIR/template.yaml"

success "✅ YAML generated: $OUTPUT_FILE"

# --- Hardened Addons (preserved from original) ---
if [ "$HARDENED" = "true" ]; then
  IFS=',' read -ra ADDONS <<< "$ADDONS_FLAGS"

  for addon in "${ADDONS[@]}"; do
    case ${addon// /} in
      1) addon_path="pdb.yaml" ;;
      2) addon_path="networkpolicy.yaml" ;;
      3) addon_path="tls-ingress.yaml" ;;
      4) addon_path="resourcequota.yaml" ;;
      5) addon_path="monitoring-servicemonitor.yaml" ;;
      6) addon_path="vault-secretprovider.yaml" ;;
      7) addon_path="istio-mtls.yaml" ;;
      *) continue ;;
    esac

    addon_cache="$CACHE_DIR/addons/$addon_path"
    mkdir -p "$(dirname "$addon_cache")"

    info "📦 Adding addon: $addon_path"

    if [ "$ONLINE" = true ] && curl -sf "$REPO_URL/addons/$addon_path" -o "$OUT_DIR/addon.yaml"; then
      cp "$OUT_DIR/addon.yaml" "$addon_cache"
      success "✅ Added from GitHub"

    elif [ -f "$addon_cache" ]; then
      cp "$addon_cache" "$OUT_DIR/addon.yaml"
      success "📦 Used cached addon"

    else
      warn "⚠️ Addon $addon_path not available"
      continue
    fi

    echo -e "\n---\n" >> "$OUTPUT_FILE"
    cat "$OUT_DIR/addon.yaml" >> "$OUTPUT_FILE"
    rm -f "$OUT_DIR/addon.yaml"
  done
fi

# --- Optional Validation / Apply ---
if [[ "$DRYRUN" == "true" && $(command -v kubectl) ]]; then
  info "🔍 Validating YAML via kubectl dry-run..."
  kubectl apply --dry-run=client -f "$OUTPUT_FILE"
fi

if [[ "$APPLY" == "true" && $(command -v kubectl) ]]; then
  info "🚀 Applying YAML to cluster..."
  kubectl apply -f "$OUTPUT_FILE"
fi

# --- Output Preview ---
echo ""
info "📄 Preview of generated file:"
echo "-------------------------------------------"
head -n 25 "$OUTPUT_FILE"
[[ $(wc -l < "$OUTPUT_FILE") -gt 25 ]] && echo "..."
echo ""
success "🎯 Completed: $OUTPUT_FILE"
