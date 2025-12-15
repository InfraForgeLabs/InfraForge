#!/bin/bash
# CloudFormation — Infrastructure as Code

echo "=========== CloudFormation Module ==========="
echo "1) List Stacks"
echo "2) Create Stack"
echo "3) Delete Stack"
echo "4) Describe Stack"
echo "5) Back"
read -e -p "Select option [1-5]: " cfopt

case $cfopt in
  1) aws cloudformation list-stacks ;;
  2) read -e -p "Template file path: " file; read -e -p "Stack name: " stack; aws cloudformation create-stack --stack-name "$stack" --template-body file://"$file" ;;
  3) read -e -p "Stack name: " stack; aws cloudformation delete-stack --stack-name "$stack" ;;
  4) read -e -p "Stack name: " stack; aws cloudformation describe-stacks --stack-name "$stack" ;;
  5) return ;;
  *) echo "❌ Invalid option." ;;
esac
