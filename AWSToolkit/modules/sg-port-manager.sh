#!/bin/bash
set -euo pipefail

# --- Colors for UI ---
CYAN="\e[96m"; GREEN="\e[92m"; YELLOW="\e[93m"; RED="\e[91m"; RESET="\e[0m"

# --- Dependency Check ---
for cmd in aws jq; do
  if ! command -v "$cmd" &>/dev/null; then
    if [[ "$cmd" == "jq" ]]; then
      echo -e "${YELLOW}⚙️ jq not found — installing quietly...${RESET}"

      if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt-get &>/dev/null; then
          sudo apt-get update -qq && sudo apt-get install -y jq >/dev/null 2>&1
        elif command -v yum &>/dev/null; then
          sudo yum install -y jq >/dev/null 2>&1
        elif command -v dnf &>/dev/null; then
          sudo dnf install -y jq >/dev/null 2>&1
        else
          echo -e "${RED}❌ Could not determine package manager to install jq.${RESET}"
          exit 1
        fi
      elif [[ "$OSTYPE" == "darwin"* ]]; then
        if command -v brew &>/dev/null; then
          brew install jq >/dev/null 2>&1
        else
          echo -e "${RED}❌ Homebrew not found. Install jq manually: brew install jq${RESET}"
          exit 1
        fi
      else
        echo -e "${RED}❌ Unsupported OS — please install jq manually.${RESET}"
        exit 1
      fi

      echo -e "${GREEN}✅ jq installed successfully.${RESET}"
    else
      echo -e "${RED}❌ AWS CLI not found. Install it via 'sudo apt install awscli -y' or 'sudo dnf install awscli -y'.${RESET}"
      exit 1
    fi
  fi
done

# --- Check AWS Credentials ---
if ! aws sts get-caller-identity >/dev/null 2>&1; then
  echo -e "${RED}❌ AWS credentials not configured. Run 'aws configure' first.${RESET}"
  exit 1
fi

# --- Region awareness ---
REGION=$(aws configure get region || true)
if [[ -z "${REGION:-}" ]]; then
  REGION="us-east-1"
  echo -e "${YELLOW}⚠️ No default region found — using ${REGION}.${RESET}"
fi

# --- Header ---
echo -e "${CYAN}🔍 Fetching all Security Groups and their associated EC2 instances (Region: $REGION)...${RESET}\n"

# --- Fetch all SGs ---
SG_LIST=$(aws ec2 describe-security-groups \
  --region "$REGION" \
  --query "SecurityGroups[].{ID:GroupId,Name:GroupName,Desc:Description}" \
  --output json)

if [[ $(echo "$SG_LIST" | jq length) -eq 0 ]]; then
  echo -e "${RED}❌ No Security Groups found in this AWS account or region.${RESET}"
  exit 1
fi

INDEX=1
TMP_FILE=$(mktemp)

# --- Display Table ---
echo "----------------------------------------------------------------------------------------"
printf "| %-3s | %-20s | %-25s | %-20s |\n" "No" "SG-ID" "SG-Name" "Instances Attached"
echo "----------------------------------------------------------------------------------------"

for row in $(echo "$SG_LIST" | jq -r '.[] | @base64'); do
  _jq() { echo "$row" | base64 --decode | jq -r "$1"; }
  SG_ID=$(_jq '.ID')
  SG_NAME=$(_jq '.Name')

  INSTANCES=$(aws ec2 describe-instances \
    --region "$REGION" \
    --filters "Name=instance.group-id,Values=$SG_ID" \
    --query "Reservations[].Instances[].InstanceId" \
    --output text 2>/dev/null || true)

  [[ -z "$INSTANCES" ]] && INSTANCES="—"

  printf "| %-3s | %-20s | %-25s | %-20s |\n" "$INDEX" "$SG_ID" "$SG_NAME" "$INSTANCES"
  echo "$INDEX $SG_ID" >>"$TMP_FILE"
  ((INDEX++))
done

echo "----------------------------------------------------------------------------------------"

# --- Select SG ---
read -rp "Select a Security Group number to manage ports: " CHOICE
SG_ID=$(awk -v num="$CHOICE" '$1==num {print $2}' "$TMP_FILE")

if [[ -z "$SG_ID" ]]; then
  echo -e "${RED}❌ Invalid selection.${RESET}"
  rm -f "$TMP_FILE"
  exit 1
fi

SG_NAME=$(aws ec2 describe-security-groups \
  --region "$REGION" \
  --group-ids "$SG_ID" \
  --query "SecurityGroups[0].GroupName" \
  --output text)

echo -e "\n${GREEN}✅ Selected Security Group:${RESET} $SG_NAME ($SG_ID)"

# --- List Instances in Selected SG ---
INSTANCES_JSON=$(aws ec2 describe-instances \
  --region "$REGION" \
  --filters "Name=instance.group-id,Values=$SG_ID" \
  --query "Reservations[].Instances[].{ID:InstanceId,Name:Tags[?Key=='Name']|[0].Value,PrivateIP:PrivateIpAddress}" \
  --output json)

echo -e "\n${CYAN}🖥️  Instances attached to $SG_NAME:${RESET}"

if [[ $(echo "$INSTANCES_JSON" | jq length) -eq 0 ]]; then
  echo "-----------------------------------------------------"
  echo "| No EC2 instances are currently using this SG.     |"
  echo "-----------------------------------------------------"
else
  echo "-----------------------------------------------------"
  printf "| %-15s | %-15s | %-15s |\n" "ID" "Name" "PrivateIP"
  echo "|-----------------|------------------|----------------|"
  echo "$INSTANCES_JSON" | jq -r '.[] | "| \(.ID) | \(.Name // "N/A") | \(.PrivateIP // "N/A") |"'
  echo "-----------------------------------------------------"
fi

# --- Ask for Port Rule ---
echo -e "\n${YELLOW}⚙️  Configure New Ingress Rule:${RESET}"
read -rp "Enter port number to open (e.g., 22, 8081, 443): " PORT
read -rp "Enter protocol (default tcp): " PROTOCOL
PROTOCOL=${PROTOCOL:-tcp}
read -rp "Enter CIDR (default 0.0.0.0/0): " CIDR
CIDR=${CIDR:-0.0.0.0/0}

# --- Validate port and CIDR ---
if ! [[ "$PORT" =~ ^[0-9]+$ ]] || ((PORT < 1 || PORT > 65535)); then
  echo -e "${RED}❌ Invalid port number: $PORT${RESET}"
  rm -f "$TMP_FILE"
  exit 1
fi
if ! [[ "$CIDR" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}$ ]]; then
  echo -e "${RED}❌ Invalid CIDR format: $CIDR${RESET}"
  rm -f "$TMP_FILE"
  exit 1
fi

# --- Confirm ---
echo -e "\n${YELLOW}Applying rule: ${RESET}Port ${GREEN}$PORT${RESET} / Protocol ${GREEN}$PROTOCOL${RESET} / CIDR ${GREEN}$CIDR${RESET}"
read -rp "Proceed? (y/n): " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
  echo -e "${RED}❌ Operation cancelled.${RESET}"
  rm -f "$TMP_FILE"
  exit 0
fi

# --- Apply the rule ---
aws ec2 authorize-security-group-ingress \
  --region "$REGION" \
  --group-id "$SG_ID" \
  --protocol "$PROTOCOL" \
  --port "$PORT" \
  --cidr "$CIDR"

echo -e "\n${GREEN}✅ Port $PORT successfully opened in $SG_NAME ($SG_ID) in region $REGION.${RESET}"

rm -f "$TMP_FILE"
