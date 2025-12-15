#!/bin/bash
# IAM Module — Manage Users, Roles, and Policies

echo "=========== IAM Module ==========="
echo "1) List Users"
echo "2) Create User"
echo "3) Attach Admin Policy"
echo "4) List Roles"
echo "5) Back"
read -e -p "Select option [1-5]: " iamopt

case $iamopt in
  1) aws iam list-users ;;
  2) read -e -p "Enter username: " user; aws iam create-user --user-name "$user" ;;
  3) read -e -p "Enter username: " user; aws iam attach-user-policy --user-name "$user" --policy-arn arn:aws:iam::aws:policy/AdministratorAccess ;;
  4) aws iam list-roles ;;
  5) return ;;
  *) echo "❌ Invalid option." ;;
esac
