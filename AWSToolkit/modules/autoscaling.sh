#!/bin/bash
# AWS Auto Scaling — AWS Toolkit
MODULE_NAME="Auto Scaling"
info "🚀 Loaded module: $MODULE_NAME"

[[ -z "$PROFILE" ]] && PROFILE="default"
[[ -z "$REGION" ]] && REGION="ap-south-1"

show_menu() {
  echo "========================================="
  echo "     📈 AWS AUTO SCALING MENU"
  echo "========================================="
  echo "1) List Auto Scaling Groups"
  echo "2) Describe Policies"
  echo "3) Manually Set Desired Capacity"
  echo "4) Return to Main Menu"
  echo "-----------------------------------------"
}

while true; do
  show_menu
  read -e -p "Select option [1-4]: " choice
  case $choice in
    1) aws autoscaling describe-auto-scaling-groups --profile "$PROFILE" --region "$REGION" --output table ;;
    2) aws autoscaling describe-policies --profile "$PROFILE" --region "$REGION" --output table ;;
    3)
      read -e -p "Enter Auto Scaling Group Name: " name
      read -e -p "Enter Desired Capacity: " cap
      aws autoscaling set-desired-capacity --auto-scaling-group-name "$name" --desired-capacity "$cap" --profile "$PROFILE" --region "$REGION"
      success "✅ Desired capacity updated."
      ;;
    4) success "⬅️ Returning to main menu..."; break ;;
    *) error "Invalid choice."; ;;
  esac
  read -e -p "Press ENTER to continue..." dummy
done
