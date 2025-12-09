#!/bin/bash
# AWS Elastic Load Balancer — AWS Toolkit
MODULE_NAME="Elastic Load Balancer"
info "🚀 Loaded module: $MODULE_NAME"

[[ -z "$PROFILE" ]] && PROFILE="default"
[[ -z "$REGION" ]] && REGION="ap-south-1"

show_menu() {
  echo "========================================="
  echo "     🌐 AWS ELB MENU"
  echo "========================================="
  echo "1) List Load Balancers"
  echo "2) Describe Target Groups"
  echo "3) Check Target Health"
  echo "4) Delete Load Balancer"
  echo "5) Return to Main Menu"
  echo "-----------------------------------------"
}

while true; do
  show_menu
  read -e -p "Select option [1-5]: " choice
  case $choice in
    1) aws elbv2 describe-load-balancers --profile "$PROFILE" --region "$REGION" --output table ;;
    2) aws elbv2 describe-target-groups --profile "$PROFILE" --region "$REGION" --output table ;;
    3)
      read -e -p "Enter Target Group ARN: " arn
      aws elbv2 describe-target-health --target-group-arn "$arn" --profile "$PROFILE" --region "$REGION"
      ;;
    4)
      read -e -p "Enter Load Balancer ARN: " arn
      aws elbv2 delete-load-balancer --load-balancer-arn "$arn" --profile "$PROFILE" --region "$REGION"
      ;;
    5) success "⬅️ Returning to main menu..."; break ;;
    *) error "Invalid choice."; ;;
  esac
  read -e -p "Press ENTER to continue..." dummy
done
