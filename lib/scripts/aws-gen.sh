#!/bin/bash
VERSION="2.9.1"
REPO_URL="https://raw.githubusercontent.com/InfraForgeLabs/InfraForge/main/AWSToolkit/"
TOOLKIT_DIR="AWSToolkit"
CACHE_DIR=".cache/awstoolkit"
CONFIG_FILE="$HOME/.awstoolkit/config"
LOG_DIR="$HOME/.awstoolkit/logs"

mkdir -p "$CACHE_DIR" "$LOG_DIR"

# --- Colors & Logging ---
timestamp() { date +"%H:%M:%S"; }
info()    { echo -e "\033[1;34m[$(timestamp)] $1\033[0m"; }
success() { echo -e "\033[1;32m[$(timestamp)] $1\033[0m"; }
warn()    { echo -e "\033[1;33m[$(timestamp)] $1\033[0m"; }
error()   { echo -e "\033[1;31m[$(timestamp)] $1\033[0m"; }
log()     { echo "[$(date '+%F %T')] $*" >> "$LOG_DIR/toolkit.log"; }

# --- Log Rotation ---
if [[ -f "$LOG_DIR/toolkit.log" && $(stat -c%s "$LOG_DIR/toolkit.log" 2>/dev/null || echo 0) -gt 5242880 ]]; then
  mv "$LOG_DIR/toolkit.log" "$LOG_DIR/toolkit_$(date +%F_%H%M).log"
  touch "$LOG_DIR/toolkit.log"
  info "🧾 Log rotated due to size >5MB."
fi

RESET_CONFIG=false
SHOW_CONTEXT=false
USE_CACHE=""

USE_CACHE=""


# --- CLI Args ---
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --module) MODULE="$2"; shift ;;
    --action) ACTION="$2"; shift ;;
    --region) REGION="$2"; shift ;;
    --profile) PROFILE="$2"; shift ;;
    --reset) RESET_CONFIG=true ;;
    --context) SHOW_CONTEXT=true ;;
    --list) ACTION="list" ;;
    --cache) USE_CACHE="true" ;;
    --quick|-q) MODULE="menu" ;;
    --help|-h)
      echo "============================================================"
      echo "☁️  AWS Toolkit CLI v$VERSION — Help Menu"
      echo "============================================================"
      echo ""
      echo "Usage:"
      echo "  bash AWSToolkit.sh [--module ec2|s3|sg-port-manager ...] [--action list|start|stop]"
      echo ""
      echo "Options:"
      echo "  --module <service>     AWS Service (ec2, s3, iam, lambda, etc.)"
      echo "  --action <cmd>         Action or subcommand"
      echo "  --region <aws-region>  AWS Region override"
      echo "  --profile <name>       AWS CLI profile"
      echo "  --context              Show saved profile & region"
      echo "  --reset                Clear saved profile/region and re-prompt"
      echo "  --cache                Enable caching mode"
      echo "  --quick                Launch main menu directly"
      echo ""
      exit 0 ;;
    *) warn "⚠️ Unknown flag: $1" ;;
  esac
  shift
done

# --- Version Check ---
LATEST_VERSION=$(curl -sf --max-time 5 "${REPO_URL}VERSION" 2>/dev/null)
if [[ -n "$LATEST_VERSION" && "$LATEST_VERSION" != "$VERSION" ]]; then
  warn "🆕 New version available: $LATEST_VERSION (You’re on $VERSION)"
fi

# --- Reset Config ---
if [[ "$RESET_CONFIG" == true ]]; then
  rm -f "$CONFIG_FILE" && success "🧹 Cleared saved profile & region from $CONFIG_FILE"
  info "Next run will ask for new profile & region."
  exit 0
fi

# --- Secure Config Load ---
if [[ -f "$CONFIG_FILE" ]]; then
  source "$CONFIG_FILE"
fi

# --- Online Check ---
TEST_URL="$REPO_URL/modules/ec2.sh"
if curl -sfI --max-time 5 "$TEST_URL" >/dev/null 2>&1; then
  ONLINE=true
  success "🌐 Online mode — modules will be fetched from GitHub."
else
  ONLINE=false
  warn "⚠️ Offline mode — using local modules only."
fi

# --- AWS CLI Check ---
if ! command -v aws &>/dev/null; then
  error "❌ AWS CLI not found. Install via 'sudo apt install awscli -y' or 'brew install awscli'."
  exit 1
fi

# --- Default Environment ---
PROFILE=${PROFILE:-"default"}
REGION=${REGION:-"ap-south-1"}
MODULE=${MODULE:-"menu"}

# --- Context Setup Function (Reusable) ---
configure_context() {
  echo ""
  echo "============================================================"
  echo "🧭 AWS Toolkit — Configure Profile & Region"
  echo "============================================================"

  echo ""
  echo "🔹 Available AWS CLI Profiles:"
   mapfile -t PROFILES < <(aws configure list-profiles 2>/dev/null)
  if [[ ${#PROFILES[@]} -eq 0 ]]; then
    PROFILES=("default")
  fi
  i=1; for p in "${PROFILES[@]}"; do printf "%2d) %s  " "$i" "$p"; ((i%3==0))&&echo ""; ((i++)); done; echo ""
  read -p "Select AWS Profile (default: $PROFILE): " PROFILE_CHOICE
  [[ "$PROFILE_CHOICE" =~ ^[0-9]+$ ]] && PROFILE="${PROFILES[$((PROFILE_CHOICE-1))]:-$PROFILE}"

  echo -e "\n🧪 Validating credentials for profile: $PROFILE ..."
  if aws sts get-caller-identity --profile "$PROFILE" --output text >/dev/null 2>&1; then
    success "✅ Credentials valid for profile: $PROFILE"
  else
    error "❌ Invalid credentials for profile: $PROFILE — using default"
    PROFILE="default"
  fi

  echo ""
  echo "🔹 Available AWS Regions:"
  mapfile -t REGIONS < <(
  aws ec2 describe-regions \
    --query "Regions[].RegionName" \
    --output text \
    --profile "$PROFILE" \
    2>/dev/null
  )

  if [[ ${#REGIONS[@]} -eq 0 ]]; then
    REGIONS=("us-east-1" "us-west-1" "us-west-2" "ap-south-1" "ap-southeast-1" "eu-central-1" "eu-west-1")
  fi
  i=1; for r in "${REGIONS[@]}"; do printf "%2d) %s  " "$i" "$r"; ((i%3==0))&&echo ""; ((i++)); done; echo ""
  read -e -p "Select AWS Region (default: $REGION): " REGION_CHOICE
  REGION=${REGIONS[$((REGION_CHOICE-1))]:-$REGION}

  mkdir -p "$(dirname "$CONFIG_FILE")"
  cat >"$CONFIG_FILE" <<EOF
PROFILE="$PROFILE"
REGION="$REGION"
EOF
  success "✅ Context saved → $CONFIG_FILE"
  success "✅ Using Profile: $PROFILE | Region: $REGION"
}

# --- Run context setup if no config exists ---
if [[ -f "$CONFIG_FILE" ]]; then
  while IFS='=' read -r key value; do
    case "$key" in
      PROFILE|REGION) printf -v "$key" '%s' "${value//\"/}" ;;
    esac
  done < "$CONFIG_FILE"
fi


# --- Always show current context ---
echo ""
echo "============================================================"
echo "🌍 Current Context: Profile=$PROFILE | Region=$REGION"
echo "============================================================"
echo ""

# --- Module Fetch Function ---
fetch_module() {
  local module="$1"
  local cache_file="$CACHE_DIR/${module}.sh"
  local url_core="$REPO_URL/modules/${module}.sh"
  local url_infra="$REPO_URL/infra/${module}.sh"
  local tmp_file; tmp_file=$(mktemp)
  if [ "$ONLINE" = true ]; then
    for url in "$url_core" "$url_infra"; do
      if curl -Lsf --max-time 5 "$url" -o "$tmp_file" && grep -q '#!/bin/bash' "$tmp_file"; then
        success "☁️ Loaded module '$module'"
        [ "$USE_CACHE" = "true" ] && cp "$tmp_file" "$cache_file"
        source "$tmp_file"; rm -f "$tmp_file"; return 0
      fi
    done
  fi
  [ -f "$cache_file" ] && { warn "📦 Using cached '$module'"; source "$cache_file"; return 0; }
  [ -f "$TOOLKIT_DIR/modules/$module.sh" ] && { source "$TOOLKIT_DIR/modules/$module.sh"; return 0; }
  [ -f "$TOOLKIT_DIR/infra/$module.sh" ] && { source "$TOOLKIT_DIR/infra/$module.sh"; return 0; }
  error "❌ Module '$module' not found."; return 1
}

# --- Main Menu ---
if [[ "$MODULE" == "menu" ]]; then
  while true; do
    clear
    echo "========================================="
    echo "     🧰 AWS TOOLKIT — MAIN MENU          "
    echo "========================================="
    echo "Profile: $PROFILE | Region: $REGION"
    echo "-----------------------------------------"
    echo "CORE MODULES (v1)"
    echo " 1) EC2          (Compute)"
    echo " 2) S3           (Storage)"
    echo " 3) IAM          (Access Control)"
    echo " 4) Lambda       (Serverless)"
    echo " 5) CloudWatch   (Monitoring)"
    echo " 6) EKS/ECS      (Containers)"
    echo " 7) ECR          (Container Registry)"
    echo " 8) RDS          (Databases)"
    echo " 9) GuardDuty    (Security)"
    echo "10) Billing      (Cost Explorer)"
    echo ""
    echo "INFRASTRUCTURE MODULES (v2)"
    echo "11) CloudFormation (IaC)"
    echo "12) VPC             (Networking)"
    echo "13) Route53         (DNS)"
    echo "14) CloudFront      (CDN)"
    echo "15) EventBridge     (Event Rules)"
    echo "16) Step Functions  (Workflows)"
    echo "17) KMS             (Encryption Keys)"
    echo "18) DynamoDB        (NoSQL)"
    echo "19) WAF             (Firewall)"
    echo "20) Config          (Compliance)"
    echo "21) SG Port Manager (Security Groups)"
    echo ""
    echo "DEVOPS AUTOMATION MODULES (v3)"
    echo "22) CodePipeline     (CI/CD Orchestrator)"
    echo "23) CodeBuild        (CI Build Service)"
    echo "24) CodeDeploy       (Automated Deployments)"
    echo "25) Systems Manager  (SSM Automation)"
    echo "26) Secrets Manager  (Secure Config Storage)"
    echo "27) CloudTrail       (Audit & Compliance)"
    echo "28) Auto Scaling     (Dynamic Scaling)"
    echo "29) Elastic Load Balancer (Traffic Routing)"
    echo ""
    echo "UTILITY OPTIONS"
    echo "30) Exit"
    echo "31) ⚙️  Change Profile / Region"
    echo "-----------------------------------------"
    read -e -p "Select option(s) [1-31]: " opt_input

    case $opt_input in
      1) MODULE="ec2";;
      2) MODULE="s3";;
      3) MODULE="iam";;
      4) MODULE="lambda";;
      5) MODULE="cloudwatch";;
      6) MODULE="eks";;
      7) MODULE="ecr";;
      8) MODULE="rds";;
      9) MODULE="guardduty";;
      10) MODULE="billing";;
      11) MODULE="cloudformation";;
      12) MODULE="vpc";;
      13) MODULE="route53";;
      14) MODULE="cloudfront";;
      15) MODULE="eventbridge";;
      16) MODULE="stepfunctions";;
      17) MODULE="kms";;
      18) MODULE="dynamodb";;
      19) MODULE="waf";;
      20) MODULE="config";;
      21) MODULE="sg-port-manager";;
      22) MODULE="codepipeline";;
      23) MODULE="codebuild";;
      24) MODULE="codedeploy";;
      25) MODULE="ssm";;
      26) MODULE="secrets";;
      27) MODULE="cloudtrail";;
      28) MODULE="autoscaling";;
      29) MODULE="elb";;
      30) success "👋 Exiting AWSToolkit."; exit 0;;
      31) configure_context; continue;;
      *) error "Invalid option: $opt_input"; continue;;
    esac

    echo ""
    echo "========================================="
    echo "🕒 Executing module: $MODULE @ $(date '+%F %T')"
    echo "========================================="
    echo ""

    fetch_module "$MODULE" || exit 1

    echo ""
    read -p "Press ENTER to return to main menu..." dummy
  done
fi

success "✅ AWS Toolkit execution complete."
exit 0
