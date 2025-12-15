#!/bin/bash
# AWS CodePipeline Management Module — AWS Toolkit
# Author: Gaurav Chile
# Version: 1.0.0

MODULE_NAME="CodePipeline"
info "🚀 Loaded module: $MODULE_NAME"

[[ -z "$PROFILE" ]] && PROFILE="default"
[[ -z "$REGION" ]] && REGION="ap-south-1"

show_menu() {
  echo "========================================="
  echo "     🛠️  AWS CODEPIPELINE MENU"
  echo "========================================="
  echo "Profile: $PROFILE | Region: $REGION"
  echo "-----------------------------------------"
  echo "1) List Pipelines"
  echo "2) View Pipeline Details"
  echo "3) Start Pipeline Execution"
  echo "4) Get Pipeline Execution Status"
  echo "5) Delete Pipeline"
  echo "6) Return to Main Menu"
  echo "-----------------------------------------"
}

while true; do
  show_menu
  read -e -p "Select an option [1-6]: " choice
  case $choice in
    1)
      info "📋 Listing Pipelines..."
      aws codepipeline list-pipelines --profile "$PROFILE" --region "$REGION" --output table
      ;;
    2)
      read -e -p "Enter pipeline name: " name
      aws codepipeline get-pipeline --name "$name" --profile "$PROFILE" --region "$REGION"
      ;;
    3)
      read -e -p "Enter pipeline name to start: " name
      aws codepipeline start-pipeline-execution --name "$name" --profile "$PROFILE" --region "$REGION"
      success "✅ Pipeline '$name' started."
      ;;
    4)
      read -e -p "Enter pipeline name: " name
      aws codepipeline list-pipeline-executions --pipeline-name "$name" --profile "$PROFILE" --region "$REGION" --output table
      ;;
    5)
      read -e -p "Enter pipeline name to delete: " name
      aws codepipeline delete-pipeline --name "$name" --profile "$PROFILE" --region "$REGION"
      success "🗑️ Pipeline '$name' deleted."
      ;;
    6) success "⬅️ Returning to main menu..."; break ;;
    *) error "Invalid option."; ;;
  esac
  read -e -p "Press ENTER to continue..." dummy
done
