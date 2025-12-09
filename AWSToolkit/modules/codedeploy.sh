#!/bin/bash
# AWS CodeDeploy Management Module — AWS Toolkit
MODULE_NAME="CodeDeploy"
info "🚀 Loaded module: $MODULE_NAME"

[[ -z "$PROFILE" ]] && PROFILE="default"
[[ -z "$REGION" ]] && REGION="ap-south-1"

show_menu() {
  echo "========================================="
  echo "     🚀 AWS CODEDEPLOY MENU"
  echo "========================================="
  echo "Profile: $PROFILE | Region: $REGION"
  echo "-----------------------------------------"
  echo "1) List Applications"
  echo "2) List Deployment Groups"
  echo "3) Create Deployment"
  echo "4) Get Deployment Status"
  echo "5) Delete Application"
  echo "6) Return to Main Menu"
  echo "-----------------------------------------"
}

while true; do
  show_menu
  read -e -p "Select an option [1-6]: " choice
  case $choice in
    1)
      aws deploy list-applications --profile "$PROFILE" --region "$REGION" --output table
      ;;
    2)
      read -e -p "Enter application name: " app
      aws deploy list-deployment-groups --application-name "$app" --profile "$PROFILE" --region "$REGION" --output table
      ;;
    3)
      read -e -p "Enter application name: " app
      read -e -p "Enter deployment group: " group
      aws deploy create-deployment --application-name "$app" --deployment-group-name "$group" \
        --ignore-application-stop-failures --profile "$PROFILE" --region "$REGION"
      success "🚀 Deployment initiated for '$app'."
      ;;
    4)
      read -e -p "Enter deployment ID: " dep
      aws deploy get-deployment --deployment-id "$dep" --profile "$PROFILE" --region "$REGION"
      ;;
    5)
      read -e -p "Enter application name: " app
      aws deploy delete-application --application-name "$app" --profile "$PROFILE" --region "$REGION"
      success "🗑️ Application '$app' deleted."
      ;;
    6) success "⬅️ Returning to main menu..."; break ;;
    *) error "Invalid option."; ;;
  esac
  read -e -p "Press ENTER to continue..." dummy
done
