#!/bin/bash
REPO_URL="https://raw.githubusercontent.com/InfraForgeLabs/InfraForge/main/MonitoringTemplates"
OUT_DIR="${HOME:?HOME is not set}/InfraForge/monitoring-templates"
CACHE_DIR=".cache/monitoring-templates"
mkdir -p "$OUT_DIR" "$CACHE_DIR"

VERSION="v3.2"
DATE=$(date +"%Y-%m-%d %H:%M:%S")

# --- Colors & Logging ---
timestamp() { date +"%H:%M:%S"; }
info()    { echo -e "\033[1;34m[$(timestamp)] $1\033[0m"; }
success() { echo -e "\033[1;32m[$(timestamp)] $1\033[0m"; }
warn()    { echo -e "\033[1;33m[$(timestamp)] $1\033[0m"; }
error()   { echo -e "\033[1;31m[$(timestamp)] $1\033[0m"; }

# --- Defaults ---
MODE=""
mode=""
ADDON=""
PROJECT=""
APP=""
NS=""
IMAGE=""
PORT=""
SLACK_URL=""
SLACK_CHANNEL=""
RETENTION=""
HELM="false"
DRYRUN="false"


# --- CLI Args ---
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --mode) MODE="$2"; shift ;;
    --addon) ADDON="$2"; shift ;;
    --project) PROJECT="$2"; shift ;;
    --app) APP="$2"; shift ;;
    --ns|--namespace) NS="$2"; shift ;;
    --image) IMAGE="$2"; shift ;;
    --port) PORT="$2"; shift ;;
    --slack-url) SLACK_URL="$2"; shift ;;
    --slack-channel) SLACK_CHANNEL="$2"; shift ;;
    --retention) RETENTION="$2"; shift ;;
    --helm) HELM="true" ;;
    --dryrun) DRYRUN="true" ;;
    --help|-h)
      echo "============================================================"
      echo "📊 Monitoring Stack Template Generator v3.2 — Help & Usage"
      echo "============================================================"
      echo ""
      echo "USAGE:"
      echo "  bash monitoring-template.sh [options]"
      echo ""
      echo "OPTIONS:"
      echo "  --mode <prometheus|grafana|loki|alertmanager|addon>  Select stack type"
      echo "  --addon <1-8>                                        Addon ID (for --mode addon)"
      echo "  --project <name>                                     Project name"
      echo "  --app <name>                                         App name (optional)"
      echo "  --ns <namespace>                                     Namespace (optional)"
      echo "  --image <image:tag>                                  Image (optional)"
      echo "  --port <port>                                        Port (optional)"
      echo "  --slack-url <url>                                    Slack webhook URL (for addon 8)"
      echo "  --slack-channel <#channel>                           Slack channel name"
      echo "  --retention <period>                                 Loki retention (e.g., 720h)"
      echo "  --helm                                               Include Helm & Kustomize scaffolding"
      echo "  --dryrun                                             Validate with kubectl dry-run"
      echo ""
      echo "EXAMPLES:"
      echo "  bash monitoring-template.sh --mode prometheus --project demo"
      echo "  bash monitoring-template.sh --mode grafana --project web --helm"
      echo "  bash monitoring-template.sh --mode addon --addon 8 --slack-url https://hooks.slack.com/xxx"
      echo ""
      exit 0
      ;;
    *) warn "⚠️ Unknown flag: $1" ;;
  esac
  shift
done

# --- Online Detection ---
CHECK_URL="$REPO_URL/prometheus/prometheus.yml"
if curl -sfI "$CHECK_URL" >/dev/null 2>&1; then
  ONLINE=true
  success "🌐 Online mode detected — templates will be fetched from GitHub."
else
  ONLINE=false
  warn "⚠️ Offline mode — using cached or local templates."
fi

# --- Mode Selection ---
if [ -z "$MODE" ]; then
  echo "============================================"
  info " 📊 Monitoring Stack Template Generator v3.2"
  echo "============================================"
  echo "Select monitoring components to generate (comma-separated):"
  echo "1) Prometheus"
  echo "2) Grafana"
  echo "3) Loki + Promtail"
  echo "4) Alertmanager"
  echo "5) Addons (Exporters / Dashboards / Slack)"
  read -e -p "Your choice [1-5 or 1,2,3]: " mode
fi

if [ -n "$MODE" ]; then
  mode="$MODE"
fi

IFS=',' read -ra MODES <<< "$mode"

# --- Project Name ---
if [ -z "$PROJECT" ]; then
  read -e -p "Enter project name: " PROJECT
fi
DEST_DIR="$OUT_DIR/$PROJECT"
mkdir -p "$DEST_DIR"

# --- Template Fetch ---
fetch_file() {
  local relpath="$1"
  local dest="$2"
  local cache="$CACHE_DIR/$relpath"
  mkdir -p "$(dirname "$cache")"
  mkdir -p "$(dirname "$dest")"

  if [ "$ONLINE" = true ] && curl -sf --retry 3 --retry-delay 2 "$REPO_URL/$relpath" -o "$dest"; then
    mkdir -p "$(dirname "$cache")"
    cp "$dest" "$cache" >/dev/null 2>&1
    success "✅ Downloaded $relpath"
  elif [ -f "$cache" ]; then
    cp "$cache" "$dest"; success "📦 Used cached: $(basename "$cache")"
  elif [ -f "$relpath" ]; then
    cp "$relpath" "$dest"; warn "📂 Used local fallback: $relpath"
  else
    error "❌ Missing: $relpath"
  fi
}

# --- Multi-Select Component Logic ---
generate_component() {
  local mode="$1"
  case $mode in
    1|prometheus)
      echo "Select Prometheus files (comma-separated):"
      echo "1) deployment  2) config  3) alert.rules  4) scrape-config"
      read -e -p "Choice [1-4]: " p; p=${p:-1}
      IFS=',' read -ra SEL <<< "$p"
      for s in "${SEL[@]}"; do
        case ${s// /} in
          1) file="prometheus/deployment.yaml" ;;
          2) file="prometheus/configmap.yaml" ;;
          3) file="prometheus/alert.rules" ;;
          4) file="prometheus/scrape-config.yaml" ;;
          *) continue ;;
        esac
        FILENAME="$(basename "$file")"
        fetch_file "$file" "$DEST_DIR/${PROJECT}-${FILENAME}"
      done
      ;;
    2|grafana)
      echo "Select Grafana files (comma-separated):"
      echo "1) deployment  2) configmap  3) dashboard  4) datasources"
      read -e -p "Choice [1-4]: " g; g=${g:-1}
      IFS=',' read -ra SEL <<< "$g"
      for s in "${SEL[@]}"; do
        case ${s// /} in
          1) file="grafana/dashboards/default-dashboard.json" ;;
          2) file="grafana/configmap.yaml" ;;
          3) file="grafana/dashboard.yaml" ;;
          4) file="grafana/datasources.yaml" ;;
          *) continue ;;
        esac
        FILENAME="$(basename "$file")"
        fetch_file "$file" "$DEST_DIR/${PROJECT}-${FILENAME}"
      done
      ;;
    3|loki)
      echo "Select Loki files (comma-separated):"
      echo "1) deployment  2) config  3) promtail-config"
      read -e -p "Choice [1-3]: " l; l=${l:-1}
      IFS=',' read -ra SEL <<< "$l"
      for s in "${SEL[@]}"; do
        case ${s// /} in
          1) file="loki/deployment.yaml" ;;
          2) file="loki/config.yaml" ;;
          3) file="loki/promtail-config.yaml" ;;
          *) continue ;;
        esac
        FILENAME="$(basename "$file")"
        fetch_file "$file" "$DEST_DIR/${PROJECT}-${FILENAME}"
      done
      ;;
    4|alertmanager)
      echo "Select Alertmanager files (comma-separated):"
      echo "1) deployment  2) configmap"
      read -e -p "Choice [1-2]: " a; a=${a:-1}
      IFS=',' read -ra SEL <<< "$a"
      for s in "${SEL[@]}"; do
        case ${s// /} in
          1) file="alertmanager/deployment.yaml" ;;
          2) file="alertmanager/configmap.yaml" ;;
          *) continue ;;
        esac
        FILENAME="$(basename "$file")"
        fetch_file "$file" "$DEST_DIR/${PROJECT}-${FILENAME}"
      done
      ;;
    5|addon)
      echo "Select Addons (comma-separated):"
      echo "1) Node Exporter  2) Blackbox Exporter  3) Pushgateway  4) Grafana Webhook"
      echo "5) Grafana Dashboard  6) Grafana Datasources  7) Loki Retention  8) Alertmanager Slack"
      read -e -p "Addon [1-8]: " ADDON
      IFS=',' read -ra SEL <<< "$ADDON"
      for s in "${SEL[@]}"; do
        case ${s// /} in
          1) file="addons/node-exporter-daemonset.yaml" ;;
          2) file="addons/blackbox-exporter.yaml" ;;
          3) file="addons/pushgateway.yaml" ;;
          4) file="addons/grafana-alert-webhook.yaml" ;;
          5) file="addons/grafana-dashboard.yaml" ;;
          6) file="addons/grafana-datasources.yaml" ;;
          7) file="addons/loki-retention-policy.yaml" ;;
          8) file="addons/alertmanager-slack.yaml" ;;
          *) continue ;;
        esac
        FILENAME="$(basename "$file")"
        fetch_file "$file" "$DEST_DIR/${PROJECT}-${FILENAME}"
      done
      ;;
  esac
}

# --- Generate for All Selected Modes ---
for M in "${MODES[@]}"; do
  generate_component "$M"
done

# --- Replace Placeholders ---
APP=${APP:-"monitoring-app"}
NS=${NS:-"monitoring"}
IMAGE=${IMAGE:-"nginx:latest"}
PORT=${PORT:-"9090"}
RETENTION=${RETENTION:-"720h"}
SLACK_CHANNEL=${SLACK_CHANNEL:-"#alerts"}

for f in "$DEST_DIR"/*; do
  [[ -f "$f" ]] || continue
  sed -i "s/{{APP_NAME}}/$APP/g;s/{{NAMESPACE}}/$NS/g;s/{{IMAGE}}/$IMAGE/g;s/{{PORT}}/$PORT/g;s/{{RETENTION_PERIOD}}/$RETENTION/g;s/{{SLACK_CHANNEL}}/$SLACK_CHANNEL/g" "$f"
  [[ -n "$SLACK_URL" ]] && sed -i "s|{{SLACK_API_URL}}|$SLACK_URL|g" "$f"
done

# --- Helm & Kustomize Scaffolding ---
if [[ "$HELM" == "true" ]]; then
  fetch_file "helm/Chart.yaml" "$DEST_DIR/Chart.yaml"
  fetch_file "helm/values.yaml" "$DEST_DIR/values.yaml"
  fetch_file "kustomize/kustomization.yaml" "$DEST_DIR/kustomization.yaml"
  success "🧩 Helm & Kustomize scaffolding added."
fi

# --- Validation ---
if [[ "$DRYRUN" == "true" && $(command -v kubectl) ]]; then
  info "🔍 Validating YAML..."
  kubectl apply --dry-run=client -f "$DEST_DIR" >/dev/null && success "✅ YAML validation successful."
fi

# --- Output ---
success "✅ Monitoring templates generated successfully: $DEST_DIR"
( command -v tree >/dev/null 2>&1 && tree "$DEST_DIR" ) || ls -R "$DEST_DIR"

# --- Summary Table ---
echo -e "\n--------------------------------------------"
info "📊 Summary of Generated Components:"
for M in "${MODES[@]}"; do
  case ${M// /} in
    1) echo -e " - \033[1;32mPrometheus\033[0m ✅" ;;
    2) echo -e " - \033[1;32mGrafana\033[0m ✅" ;;
    3) echo -e " - \033[1;32mLoki + Promtail\033[0m ✅" ;;
    4) echo -e " - \033[1;32mAlertmanager\033[0m ✅" ;;
    5) echo -e " - \033[1;36mAddons\033[0m 🧩" ;;
  esac
done
[[ "$HELM" == "true" ]] && echo -e " - \033[1;35mHelm/Kustomize\033[0m included"
[[ "$DRYRUN" == "true" ]] && echo -e " - \033[1;33mValidated via dry-run\033[0m"
echo " Generated on: $DATE"
echo " Version: $VERSION"
echo "--------------------------------------------"
