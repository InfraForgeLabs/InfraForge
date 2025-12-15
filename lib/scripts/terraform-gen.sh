#!/bin/bash
set -euo pipefail

REPO_URL="https://raw.githubusercontent.com/InfraForgeLabs/InfraForge/main/TerraformTemplates"
OUT_DIR="generated"
CACHE_DIR=".cache/terraform-templates"
mkdir -p "$OUT_DIR" "$CACHE_DIR"

# --- Colors & Logging ---
timestamp() { date +"%H:%M:%S"; }
info()    { echo -e "\033[1;34m[$(timestamp)] $1\033[0m"; }
success() { echo -e "\033[1;32m[$(timestamp)] $1\033[0m"; }
warn()    { echo -e "\033[1;33m[$(timestamp)] $1\033[0m"; }
error()   { echo -e "\033[1;31m[$(timestamp)] $1\033[0m"; }

# --- Dependency Check ---
for cmd in curl zip jq; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    warn "⚠️ Missing dependency: $cmd"
    if command -v apt-get >/dev/null 2>&1; then
      sudo apt-get update -qq && sudo apt-get install -y "$cmd" >/dev/null 2>&1
    elif command -v dnf >/dev/null 2>&1; then
      sudo dnf install -y "$cmd" >/dev/null 2>&1
    elif command -v yum >/dev/null 2>&1; then
      sudo yum install -y "$cmd" >/dev/null 2>&1
    elif [[ "$OSTYPE" == "darwin"* && "$cmd" == "jq" ]]; then
      brew install jq >/dev/null 2>&1
    else
      error "❌ Cannot install $cmd automatically — please install manually."
      exit 1
    fi
    success "✅ Installed $cmd"
  fi
done

# --- Terraform Installer ---
install_terraform() {
  echo ""
  info "⚙️ Installing Terraform CLI..."
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update -y >/dev/null 2>&1
    sudo apt-get install -y gnupg software-properties-common curl >/dev/null 2>&1
    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add - >/dev/null 2>&1
    sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" >/dev/null 2>&1
    sudo apt-get update -y >/dev/null 2>&1
    sudo apt-get install -y terraform >/dev/null 2>&1 && success "✅ Terraform installed via APT!"
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y dnf-plugins-core >/dev/null 2>&1
    sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/$(rpm -E %{rhel})/hashicorp.repo >/dev/null 2>&1
    sudo dnf install -y terraform >/dev/null 2>&1 && success "✅ Terraform installed via DNF!"
  elif command -v yum >/dev/null 2>&1; then
    sudo yum install -y yum-utils >/dev/null 2>&1
    sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/$(rpm -E %{rhel})/hashicorp.repo >/dev/null 2>&1
    sudo yum install -y terraform >/dev/null 2>&1 && success "✅ Terraform installed via YUM!"
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    brew install terraform >/dev/null 2>&1 && success "✅ Terraform installed via Homebrew!"
  else
    warn "⚠️ Unsupported OS — please install Terraform manually."
  fi
}

# --- CLI Argument Parsing ---
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --env) ENVIRONMENT="$2"; shift ;;
    --module) MODULE="$2"; shift ;;
    --addon) ADDON="$2"; shift ;;
    --project) PROJECT="$2"; shift ;;
    --secure) INCLUDE_SECURITY=true ;;
    --no-init) SKIP_INIT=true ;;
    --help|-h)
      echo "============================================================"
      echo "🌍 Terraform Template Generator v2.4 — Universal Edition"
      echo "============================================================"
      echo "Usage:"
      echo "  bash terraform-gen.sh [--module <name>] [--env <env>] [--addon <addon>] [--project <name>]"
      echo "Options:"
      echo "  --secure        Include security baseline (security.tf)"
      echo "  --no-init       Skip terraform init"
      echo "Examples:"
      echo "  bash terraform-gen.sh --module compute --env dev --addon backend"
      exit 0 ;;
    *) warn "⚠️ Unknown flag: $1" ;;
  esac
  shift
done

# --- Online Detection ---
CHECK_URL="$REPO_URL/modules/network/main.tf"
if curl -sfI "$CHECK_URL" >/dev/null 2>&1; then
  ONLINE=true; success "🌐 Online mode — fetching templates from GitHub."
else
  ONLINE=false; warn "⚠️ Offline mode — using cached/local templates."
fi

# --- AWS CLI Check ---
if ! command -v aws >/dev/null 2>&1; then
  warn "⚠️ AWS CLI not found. Terraform AWS provider may fail if templates depend on it."
fi

# --- Interactive Mode ---
if [ -z "${ENVIRONMENT:-}" ] && [ -z "${MODULE:-}" ] && [ -z "${ADDON:-}" ]; then
  info "💡 No flags detected — launching interactive mode."
  echo "============================================"
  info " 🌍 Terraform Template Generator v2.4 "
  echo "============================================"
  echo "Select components (comma separated):"
  echo "1) Module (Network / Compute / Storage / IAM / Monitoring)"
  echo "2) Environment (Dev / Staging / Prod)"
  echo "3) Addon (Backend / Lock / TF Cloud / Cost Estimation)"
  read -e -p "Your choice [1-3 or 1,2,3]: " modes
  modes=$(echo "$modes" | tr -d ' ')

  if [[ "$modes" =~ 1 ]]; then
    echo "Available Modules: network, compute, storage, iam, monitoring"
    read -e -p "Enter module name [network]: " MODULE
    MODULE=${MODULE:-network}
  fi

  if [[ "$modes" =~ 2 ]]; then
    echo "Available Environments: dev, staging, prod"
    read -e -p "Enter environment name [dev]: " ENVIRONMENT
    ENVIRONMENT=${ENVIRONMENT:-dev}
  fi

  if [[ "$modes" =~ 3 ]]; then
    echo "Available Addons: backend, lock, tfcloud, cost"
    read -e -p "Enter addon name [backend]: " ADDON
    ADDON=${ADDON:-backend}
  fi

  read -e -p "Enter project name [terraform-project]: " PROJECT
  PROJECT=${PROJECT:-terraform-project}
  read -e -p "Include security baseline (security.tf)? [y/N]: " secure_choice
  [[ "$secure_choice" =~ ^[Yy]$ ]] && INCLUDE_SECURITY=true
else
  PROJECT=${PROJECT:-terraform-project}
fi

# --- Confirmation ---
echo ""
echo "============================================================"
echo "🧾 Configuration Summary"
echo "============================================================"
echo "Project:      $PROJECT"
echo "Module:       ${MODULE:-none}"
echo "Environment:  ${ENVIRONMENT:-none}"
echo "Addon:        ${ADDON:-none}"
[[ "${INCLUDE_SECURITY:-false}" == true ]] && echo "Security:     Included ✅" || echo "Security:     Skipped ❌"
echo "============================================================"
read -p "Proceed with generation? (Y/n): " confirm
[[ "$confirm" =~ ^[Nn]$ ]] && { warn "❌ Cancelled by user."; exit 0; }

DEST_DIR="$OUT_DIR/$PROJECT"
mkdir -p "$DEST_DIR"

# --- Fetch Helpers ---
fetch_file() {
  local rel="$1" dest="$2" cache="$CACHE_DIR/$(basename "$rel")"
  mkdir -p "$(dirname "$dest")"
  if [ "$ONLINE" = true ] && curl -sf --retry 3 --retry-delay 2 "$REPO_URL/$rel" -o "$dest"; then
    cp "$dest" "$cache" >/dev/null 2>&1; success "✅ Downloaded: $rel"
  elif [ -f "$cache" ]; then
    cp "$cache" "$dest"; success "📦 Used cached: $(basename "$cache")"
  elif [ -f "$rel" ]; then
    cp "$rel" "$dest"; warn "📂 Used local fallback: $rel"
  else
    warn "⚠️ Missing: $rel"
  fi
}

fetch_dir() {
  local relpath="$1" dest="$2"; mkdir -p "$dest"
  for f in main.tf variables.tf outputs.tf backend.tf provider.tf locals.tf; do
    fetch_file "$relpath/$f" "$dest/$f"
  done
  fetch_file "common/versions.tf" "$dest/versions.tf"
  if [ "${INCLUDE_SECURITY:-false}" = true ]; then
    fetch_file "common/security.tf" "$dest/security.tf"
    success "🛡️ Included security baseline (security.tf)"
  fi
}

# --- Generation Logic ---
if [[ "${MODULE:-}" ]]; then
  case "$MODULE" in
    network|Network|1) path="modules/network";;
    compute|Compute|2) path="modules/compute";;
    storage|Storage|3) path="modules/storage";;
    iam|IAM|4) path="modules/iam";;
    monitoring|Monitoring|5) path="modules/monitoring";;
    *) error "Invalid module: $MODULE"; exit 1;;
  esac
  fetch_dir "$path" "$DEST_DIR/modules/$MODULE"
fi

if [[ "${ENVIRONMENT:-}" ]]; then
  case "$ENVIRONMENT" in
    dev|Dev|1) path="environments/dev";;
    staging|Staging|2) path="environments/staging";;
    prod|Prod|3) path="environments/prod";;
    *) error "Invalid environment: $ENVIRONMENT"; exit 1;;
  esac
  fetch_dir "$path" "$DEST_DIR/environments/$ENVIRONMENT"
fi

if [[ "${ADDON:-}" ]]; then
  case "$ADDON" in
    backend|Backend|1) file="addons/remote-backend.tf";;
    lock|Lock|2) file="addons/state-lock.tf";;
    tfcloud|TFCloud|3) file="addons/tfcloud-integration.tf";;
    cost|Cost|4) file="addons/cost-estimation.tf";;
    *) error "Invalid addon: $ADDON"; exit 1;;
  esac
  fetch_file "$file" "$DEST_DIR/$(basename "$file")"
fi

# --- terraform.tfvars ---
info "🧩 Generating terraform.tfvars..."
TFVARS_FILE="$DEST_DIR/terraform.tfvars"
TFVARS_URL="$REPO_URL/common/terraform.tfvars"

if [ "$ONLINE" = true ] && curl -sf --retry 3 "$TFVARS_URL" -o "$TFVARS_FILE"; then
  success "✅ Downloaded terraform.tfvars from GitHub"
else
  warn "⚠️ Using default terraform.tfvars template"
  cat > "$TFVARS_FILE" <<'EOF'
aws_region           = "{{AWS_REGION}}"
key_name             = "{{KEY_NAME}}"
ami_id               = "{{AMI_ID}}"
subnet_id            = "{{SUBNET_ID}}"
ssh_private_key_path = "{{SSH_PRIVATE_KEY_PATH}}"
dockerhub_user       = "{{DOCKERHUB_USER}}"
instance_type        = "{{INSTANCE_TYPE}}"
EOF
fi

read -e -p "Enter AWS region [ap-south-1]: " AWS_REGION
AWS_REGION=${AWS_REGION:-ap-south-1}
read -e -p "Enter key pair name [devops-key]: " KEY_NAME
KEY_NAME=${KEY_NAME:-devops-key}
read -e -p "Enter AMI ID [ami-036d2bb3f14d36e07]: " AMI_ID
AMI_ID=${AMI_ID:-ami-036d2bb3f14d36e07}
read -e -p "Enter subnet ID [subnet-0d7b820d24f65188a]: " SUBNET_ID
SUBNET_ID=${SUBNET_ID:-subnet-0d7b820d24f65188a}
read -e -p "Enter path to SSH private key [/home/dmin/devops-key.pem]: " SSH_PRIVATE_KEY_PATH
SSH_PRIVATE_KEY_PATH=${SSH_PRIVATE_KEY_PATH:-/home/dmin/devops-key.pem}
read -e -p "Enter DockerHub username [gauravchile]: " DOCKERHUB_USER
DOCKERHUB_USER=${DOCKERHUB_USER:-gauravchile}
read -e -p "Enter EC2 instance type [t3.large]: " INSTANCE_TYPE
INSTANCE_TYPE=${INSTANCE_TYPE:-t3.large}

sed -i \
  -e "s|{{AWS_REGION}}|$AWS_REGION|g" \
  -e "s|{{KEY_NAME}}|$KEY_NAME|g" \
  -e "s|{{AMI_ID}}|$AMI_ID|g" \
  -e "s|{{SUBNET_ID}}|$SUBNET_ID|g" \
  -e "s|{{SSH_PRIVATE_KEY_PATH}}|$SSH_PRIVATE_KEY_PATH|g" \
  -e "s|{{DOCKERHUB_USER}}|$DOCKERHUB_USER|g" \
  -e "s|{{INSTANCE_TYPE}}|$INSTANCE_TYPE|g" \
  "$TFVARS_FILE"

success "✅ terraform.tfvars ready at: $TFVARS_FILE"

# --- Terraform Init & Validate ---
if ! command -v terraform >/dev/null 2>&1; then
  warn "⚠️ Terraform CLI not found."
  read -e -p "Install Terraform now? [Y/n]: " install_choice
  [[ "$install_choice" =~ ^[Yy]$ ]] && install_terraform
fi

if command -v terraform >/dev/null 2>&1; then
  if [[ "${SKIP_INIT:-false}" != true ]]; then
    info "🔄 Initializing Terraform workspace..."
    (cd "$DEST_DIR" && terraform init -input=false -backend=true >/dev/null 2>&1 \
      && success "🚀 Terraform initialized successfully in $DEST_DIR" \
      || warn "⚠️ Terraform init failed — check configuration."))
  else
    info "⏩ Skipping Terraform init (--no-init flag set)."
  fi

  info "🧹 Formatting Terraform files..."
  terraform fmt -recursive "$DEST_DIR" >/dev/null 2>&1 && success "✨ Terraform files formatted."

  info "🔍 Validating Terraform configuration..."
  ( cd "$DEST_DIR" && terraform validate >/dev/null 2>&1 \
    && success "✅ Terraform configuration is valid." \
    || warn "⚠️ Terraform validation failed — please review." )
else
  warn "⚠️ Terraform CLI still not found — skipping init, format, and validation."
fi

# --- Zip Packaging ---
ZIP_FILE="$OUT_DIR/${PROJECT}-${MODULE:-bundle}.zip"
(cd "$DEST_DIR" && zip -qr "../${PROJECT}-${MODULE:-bundle}.zip" .)
success "📦 Project packaged → $ZIP_FILE"

# --- Output Summary ---
echo ""
info "📁 Generated Structure:"
( command -v tree >/dev/null 2>&1 && tree "$DEST_DIR" ) || ls -R "$DEST_DIR"
echo ""
success "✅ Terraform templates generated successfully: $DEST_DIR"
