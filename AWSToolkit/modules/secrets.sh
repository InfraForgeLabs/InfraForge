#!/bin/bash
# AWS Secrets Manager / Parameter Store — AWS Toolkit
MODULE_NAME="Secrets Manager"
info "🚀 Loaded module: $MODULE_NAME"

[[ -z "$PROFILE" ]] && PROFILE="default"
[[ -z "$REGION" ]] && REGION="ap-south-1"

show_menu() {
  echo "========================================="
  echo "     🔐 AWS SECRETS MANAGER MENU"
  echo "========================================="
  echo "1) List Secrets"
  echo "2) Get Secret Value"
  echo "3) Create Secret"
  echo "4) Delete Secret"
  echo "5) Return to Main Menu"
  echo "-----------------------------------------"
}

while true; do
  show_menu
  read -e -p "Select option [1-5]: " choice
  case $choice in
    1) aws secretsmanager list-secrets --profile "$PROFILE" --region "$REGION" --output table ;;
    2)
      read -e -p "Enter Secret Name: " name
      aws secretsmanager get-secret-value --secret-id "$name" --profile "$PROFILE" --region "$REGION"
      ;;
    3)
      read -e -p "Enter Secret Name: " name
      read -e -p "Enter Secret Value: " value
      aws secretsmanager create-secret --name "$name" --secret-string "$value" --profile "$PROFILE" --region "$REGION"
      ;;
    4)
      read -e -p "Enter Secret Name to delete: " name
      aws secretsmanager delete-secret --secret-id "$name" --force-delete-without-recovery --profile "$PROFILE" --region "$REGION"
      ;;
    5) success "⬅️ Returning to main menu..."; break ;;
    *) error "Invalid choice."; ;;
  esac
  read -e -p "Press ENTER to continue..." dummy
done
