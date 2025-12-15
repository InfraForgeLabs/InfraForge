#!/bin/bash
# AWS Systems Manager (SSM) Module — AWS Toolkit
MODULE_NAME="SSM"
info "🚀 Loaded module: $MODULE_NAME"

[[ -z "$PROFILE" ]] && PROFILE="default"
[[ -z "$REGION" ]] && REGION="ap-south-1"

show_menu() {
  echo "========================================="
  echo "     🧭 AWS SYSTEMS MANAGER MENU"
  echo "========================================="
  echo "1) List Managed Instances"
  echo "2) Send Command to EC2"
  echo "3) View Command History"
  echo "4) List SSM Documents"
  echo "5) Patch Summary"
  echo "6) Return to Main Menu"
  echo "-----------------------------------------"
}

while true; do
  show_menu
  read -e -p "Select option [1-6]: " choice
  case $choice in
    1) aws ssm describe-instance-information --profile "$PROFILE" --region "$REGION" --output table ;;
    2)
      read -e -p "Enter Instance ID: " id
      read -e -p "Enter Command: " cmd
      aws ssm send-command --instance-ids "$id" --document-name "AWS-RunShellScript" \
        --parameters commands="$cmd" --profile "$PROFILE" --region "$REGION"
      ;;
    3) aws ssm list-commands --profile "$PROFILE" --region "$REGION" --output table ;;
    4) aws ssm list-documents --profile "$PROFILE" --region "$REGION" --output table ;;
    5) aws ssm describe-instance-patch-states --profile "$PROFILE" --region "$REGION" --output table ;;
    6) success "⬅️ Returning to main menu..."; break ;;
    *) error "Invalid choice."; ;;
  esac
  read -e -p "Press ENTER to continue..." dummy
done
