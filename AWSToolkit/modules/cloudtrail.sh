#!/bin/bash
# AWS CloudTrail — AWS Toolkit
MODULE_NAME="CloudTrail"
info "🚀 Loaded module: $MODULE_NAME"

[[ -z "$PROFILE" ]] && PROFILE="default"
[[ -z "$REGION" ]] && REGION="ap-south-1"

show_menu() {
  echo "========================================="
  echo "     🕵️ AWS CLOUDTRAIL MENU"
  echo "========================================="
  echo "1) List Trails"
  echo "2) Start Logging"
  echo "3) Stop Logging"
  echo "4) Lookup Recent Events"
  echo "5) Return to Main Menu"
  echo "-----------------------------------------"
}

while true; do
  show_menu
  read -e -p "Select option [1-5]: " choice
  case $choice in
    1) aws cloudtrail list-trails --profile "$PROFILE" --region "$REGION" --output table ;;
    2)
      read -e -p "Enter Trail Name: " name
      aws cloudtrail start-logging --name "$name" --profile "$PROFILE" --region "$REGION"
      ;;
    3)
      read -e -p "Enter Trail Name: " name
      aws cloudtrail stop-logging --name "$name" --profile "$PROFILE" --region "$REGION"
      ;;
    4)
      aws cloudtrail lookup-events --max-results 10 --profile "$PROFILE" --region "$REGION" --output table
      ;;
    5) success "⬅️ Returning to main menu..."; break ;;
    *) error "Invalid choice."; ;;
  esac
  read -e -p "Press ENTER to continue..." dummy
done
