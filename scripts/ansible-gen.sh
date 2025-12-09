#!/bin/bash
REPO_URL="https://raw.githubusercontent.com/InfraForgeLabs/InfraForge/main/AnsibleTemplates"
OUT_DIR="generated"
CACHE_DIR=".cache/ansible-templates"
mkdir -p "$OUT_DIR" "$CACHE_DIR"

# ------------------- Logging -------------------
timestamp() { date +"%H:%M:%S"; }
info()    { echo -e "\033[1;34m[$(timestamp)] $1\033[0m"; }
success() { echo -e "\033[1;32m[$(timestamp)] $1\033[0m"; }
warn()    { echo -e "\033[1;33m[$(timestamp)] $1\033[0m"; }
error()   { echo -e "\033[1;31m[$(timestamp)] $1\033[0m"; }

# ------------------- Input helper -------------------
read_input() {
  local var=$1; local prompt=$2; local default=$3; local value
  read -e -p "$prompt [$default]: " value
  if [[ -z "$value" ]]; then value="$default"; fi
  eval $var="'$value'"
}

# ------------------- CLI Flags -------------------
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --type) TYPE="$2"; shift ;;
    --name) NAME="$2"; shift ;;
    --project) PROJECT="$2"; shift ;;
    --vars) VARS="$2"; shift ;;
    --attach-addons) ATTACH_ADDONS="$2"; shift ;;
    --help|-h)
      echo "============================================================"
      echo "🧩 Ansible Template Generator v2.4 — Multi-Select Edition"
      echo "============================================================"
      echo ""
      echo "Usage:"
      echo "  bash ansible-template.sh [options]"
      echo ""
      echo "Options:"
      echo "  --type <playbook|role|inventory|addon>   Template category"
      echo "  --name <template-name>                   File or role name(s)"
      echo "  --project <name>                         Project folder name"
      echo "  --vars <key=value,...>                   Optional vars for addons"
      echo "  --attach-addons <true|false>             Attach addon snippets to site.yml"
      echo ""
      exit 0 ;;
    *) warn "⚠️ Unknown flag: $1" ;;
  esac; shift
done

# ------------------- Defaults -------------------
DEFAULT_TYPE="playbook"
DEFAULT_PROJECT="ansible-project"
DEFAULT_ATTACH="false"
TYPE=${TYPE:-$DEFAULT_TYPE}
PROJECT=${PROJECT:-$DEFAULT_PROJECT}
ATTACH_ADDONS=${ATTACH_ADDONS:-$DEFAULT_ATTACH}

# ------------------- Parse Vars -------------------
if [ -n "$VARS" ]; then
  IFS=',' read -ra VAR_ARRAY <<< "$VARS"
  for v in "${VAR_ARRAY[@]}"; do
    key=$(echo "$v" | cut -d'=' -f1)
    value=$(echo "$v" | cut -d'=' -f2-)
    eval "$key='$value'"
  done
fi

# ------------------- Connectivity -------------------
CHECK_URL="$REPO_URL/playbooks/site.yml"
if curl -sfI "$CHECK_URL" >/dev/null 2>&1; then
  ONLINE=true; success "🌐 Online mode detected — fetching templates from GitHub."
else
  ONLINE=false; warn "⚠️ Offline mode — using cached/local templates."
fi

# ------------------- Interactive Menu -------------------
if [ $# -eq 0 ]; then
  echo "============================================"
  info " 🧩 Ansible Template Generator v2.4 "
  echo "============================================"
  echo "1) Playbooks"
  echo "2) Roles"
  echo "3) Inventories"
  echo "4) Addons"
  read_input mode "Select option [1-4]" "1"
  case $mode in
    1) TYPE="playbook" ;;
    2) TYPE="role" ;;
    3) TYPE="inventory" ;;
    4) TYPE="addon" ;;
  esac
  read_input PROJECT "Enter project name" "$DEFAULT_PROJECT"
fi

DEST_DIR="$OUT_DIR/$PROJECT"
mkdir -p "$DEST_DIR"

# ------------------- Fetch Helper -------------------
fetch_file() {
  local rel="$1"; local dest="$2"; local cache="$CACHE_DIR/$(basename "$rel")"
  mkdir -p "$(dirname "$dest")"
  if [ "$ONLINE" = true ] && curl -sf "$REPO_URL/$rel" -o "$dest"; then
    cp "$dest" "$cache" >/dev/null 2>&1
    success "✅ Downloaded: $rel"
    return 0
  elif [ -f "$cache" ]; then
    cp "$cache" "$dest"
    success "📦 Used cached: $(basename "$cache")"
    return 0
  elif [ -f "$rel" ]; then
    cp "$rel" "$dest"
    warn "📂 Used local: $rel"
    return 0
  else
    warn "⚠️ Missing template: $rel"
    return 1
  fi
}

# =========================================================
# 🧱 1️⃣ Playbooks (Multi-select)
# =========================================================
if [[ "$TYPE" == "playbook" ]]; then
  echo "Available Playbooks:"
  echo "1) site.yml"
  echo "2) dev.yml"
  echo "3) staging.yml"
  echo "4) prod.yml"
  echo "5) hardening.yml"
  read_input psel "Select playbooks (comma-separated)" "1"

  IFS=',' read -ra PB <<< "$psel"
  for i in "${PB[@]}"; do
    case ${i// /} in
      1) file="playbooks/site.yml" ;;
      2) file="playbooks/dev.yml" ;;
      3) file="playbooks/staging.yml" ;;
      4) file="playbooks/prod.yml" ;;
      5) file="playbooks/hardening.yml" ;;
      *) file="playbooks/site.yml"; warn "⚠️ Invalid choice, using site.yml";;
    esac
    fname=$(basename "$file")
    fetch_file "$file" "$DEST_DIR/$fname"
  done
fi

# =========================================================
# 🧱 2️⃣ Roles (Multi-select)
# =========================================================
if [[ "$TYPE" == "role" ]]; then
  echo "Available Roles:"
  echo "1) common"
  echo "2) docker"
  echo "3) k8s"
  echo "4) security"
  echo "5) monitoring"
  echo "6) user-management"
  read_input rsel "Select roles (comma-separated)" "1,2"
  IFS=',' read -ra ROLES <<< "$rsel"
  for i in "${ROLES[@]}"; do
    case ${i// /} in
      1) path="roles/common/tasks/main.yml" ;;
      2) path="roles/docker/tasks/main.yml" ;;
      3) path="roles/k8s/tasks/main.yml" ;;
      4) path="roles/security/tasks/main.yml" ;;
      5) path="roles/monitoring/tasks/main.yml" ;;
      6) path="roles/user-management/tasks/main.yml" ;;
      *) warn "⚠️ Invalid role ID"; continue ;;
    esac
    rdir="$DEST_DIR/$(dirname "$path")"
    mkdir -p "$rdir"
    fetch_file "$path" "$rdir/$(basename "$path")"
  done
fi

# =========================================================
# 🧱 3️⃣ Inventories
# =========================================================
if [[ "$TYPE" == "inventory" ]]; then
  echo "Available Inventories:"
  echo "1) static"
  echo "2) dynamic"
  read_input inv "Select inventory [1-2]" "1"
  case $inv in
    1) file="inventories/static/hosts.ini" ;;
    2) file="inventories/dynamic/aws_ec2.yml" ;;
  esac
  fetch_file "$file" "$DEST_DIR/$(basename "$file")"
fi

# =========================================================
# 🧱 4️⃣ Addons (Multi-select)
# =========================================================
if [[ "$TYPE" == "addon" ]]; then
  echo "Available Addons:"
  echo "1) Vault"
  echo "2) Slack Callback"
  echo "3) Jenkins Integration"
  echo "4) ansible.cfg"
  read_input asel "Select addons (comma-separated)" "1"
  IFS=',' read -ra ADDONS <<< "$asel"
  for a in "${ADDONS[@]}"; do
    case ${a// /} in
      1) file="addons/ansible-vault-example.yml" ;;
      2) file="addons/callback-slack.yml" ;;
      3) file="addons/jenkins-integration.yml" ;;
      4) file="addons/ansible.cfg" ;;
      *) continue ;;
    esac
    fetch_file "$file" "$DEST_DIR/$(basename "$file")"
  done
fi

# =========================================================
# 🔐 Addon Logic (Vault, Slack, Jenkins)
# =========================================================
for f in "$DEST_DIR"/*; do
  [[ ! -f "$f" ]] && continue
  case "$(basename "$f")" in
    ansible-vault-example.yml)
      vaultpass=${vault_pass:-}
      if [ -z "$vaultpass" ]; then read -s -p "Enter Vault password [changeme123]: " vaultpass; echo; vaultpass=${vaultpass:-changeme123}; fi
      sed -i "s/{{ANSIBLE_VAULT_PASS}}/$vaultpass/g" "$f"
      success "🔐 Vault password injected"
      ;;
    callback-slack.yml)
      read_input slackurl "Enter Slack Webhook URL" "https://hooks.slack.com/services/DEFAULT/HOOK/URL"
      read_input slackchannel "Enter Slack Channel" "#ansible-alerts"
      sed -i "s#{{SLACK_WEBHOOK_URL}}#$slackurl#g" "$f"
      sed -i "s#{{SLACK_CHANNEL}}#$slackchannel#g" "$f"
      success "💬 Slack details injected"
      ;;
    jenkins-integration.yml)
      read_input jenkinsurl "Enter Jenkins URL" "http://jenkins.local:8080"
      read_input jenkinsuser "Enter Jenkins username" "admin"
      read -s -p "Enter Jenkins API token [changeme123]: " jenkinstoken; echo
      jenkinstoken=${jenkinstoken:-changeme123}
      read_input jobname "Enter Jenkins Job Name" "DeployApp"
      sed -i "s#{{JENKINS_URL}}#$jenkinsurl#g" "$f"
      sed -i "s#{{JENKINS_USER}}#$jenkinsuser#g" "$f"
      sed -i "s#{{JENKINS_TOKEN}}#$jenkinstoken#g" "$f"
      sed -i "s#{{JOB_NAME}}#$jobname#g" "$f"
      success "🔗 Jenkins details injected"
      ;;
  esac
done

# =========================================================
# 🧩 Snippet Generation + Optional Attach
# =========================================================
SNIPPET_DIR="$DEST_DIR/addons-snippets"
mkdir -p "$SNIPPET_DIR"
for f in "$DEST_DIR"/*; do
  case "$(basename "$f")" in
    ansible-vault-example.yml)
      echo "- name: Vault Decrypt\n  debug: msg='Vault decrypted successfully'" > "$SNIPPET_DIR/vault-snippet.yml" ;;
    callback-slack.yml)
      echo "- name: Notify Slack\n  uri:\n    url: '$slackurl'\n    method: POST\n    body_format: json\n    body:\n      text: 'Playbook complete in $PROJECT'" > "$SNIPPET_DIR/slack-snippet.yml" ;;
    jenkins-integration.yml)
      echo "- name: Trigger Jenkins Job\n  community.general.jenkins_job_trigger:\n    url: '$jenkinsurl'\n    user: '$jenkinsuser'\n    token: '$jenkinstoken'\n    job: '$jobname'" > "$SNIPPET_DIR/jenkins-snippet.yml" ;;
  esac
done
success "📄 Addon snippets generated in $SNIPPET_DIR"

if [ $# -eq 0 ]; then
  read_input ATTACH_ADDONS "Attach addons to site.yml? (true/false)" "false"
fi

if [[ "$ATTACH_ADDONS" =~ ^[Tt]rue$ ]]; then
  target="$DEST_DIR/site.yml"
  [ ! -f "$target" ] && echo "- hosts: all\n  tasks:" > "$target"
  info "🔗 Attaching snippets to site.yml ..."
  for snip in "$SNIPPET_DIR"/*.yml; do
    cat "$snip" >> "$target"
    echo "" >> "$target"
    success "✅ Attached $(basename "$snip")"
  done
fi

echo "--------------------------------------------"
success "✅ All templates generated successfully in: $DEST_DIR"
( command -v tree >/dev/null 2>&1 && tree "$DEST_DIR" ) || ls -R "$DEST_DIR"
