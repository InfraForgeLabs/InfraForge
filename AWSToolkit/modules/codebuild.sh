#!/bin/bash
# AWS CodeBuild Management Module — AWS Toolkit
MODULE_NAME="CodeBuild"
info "🚀 Loaded module: $MODULE_NAME"

[[ -z "$PROFILE" ]] && PROFILE="default"
[[ -z "$REGION" ]] && REGION="ap-south-1"

show_menu() {
  echo "========================================="
  echo "     🧱 AWS CODEBUILD MENU"
  echo "========================================="
  echo "Profile: $PROFILE | Region: $REGION"
  echo "-----------------------------------------"
  echo "1) List Projects"
  echo "2) Start Build"
  echo "3) View Build History"
  echo "4) Stop Build"
  echo "5) Delete Project"
  echo "6) Return to Main Menu"
  echo "-----------------------------------------"
}

while true; do
  show_menu
  read -e -p "Select an option [1-6]: " choice
  case $choice in
    1)
      aws codebuild list-projects --profile "$PROFILE" --region "$REGION" --output table
      ;;
    2)
      read -e -p "Enter project name: " name
      aws codebuild start-build --project-name "$name" --profile "$PROFILE" --region "$REGION"
      success "🏗️ Build started for project '$name'."
      ;;
    3)
      read -e -p "Enter project name: " name
      aws codebuild list-builds-for-project --project-name "$name" --profile "$PROFILE" --region "$REGION" --output table
      ;;
    4)
      read -e -p "Enter build ID: " id
      aws codebuild stop-build --id "$id" --profile "$PROFILE" --region "$REGION"
      success "🛑 Build '$id' stopped."
      ;;
    5)
      read -e -p "Enter project name to delete: " name
      aws codebuild delete-project --name "$name" --profile "$PROFILE" --region "$REGION"
      success "🗑️ Project '$name' deleted."
      ;;
    6) success "⬅️ Returning to main menu..."; break ;;
    *) error "Invalid option."; ;;
  esac
  read -e -p "Press ENTER to continue..." dummy
done
