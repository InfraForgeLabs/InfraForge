#!/bin/bash
# EC2 Module — Manage Compute Instances

echo "=========== EC2 Module ==========="
echo "1) List Instances"
echo "2) Start Instance"
echo "3) Stop Instance"
echo "4) Describe Instance Status"
echo "5) Back"
read -e -p "Select option [1-5]: " ec2opt

case $ec2opt in
  1) aws ec2 describe-instances --output table ;;
  2) read -e -p "Enter Instance ID: " iid; aws ec2 start-instances --instance-ids "$iid" ;;
  3) read -e -p "Enter Instance ID: " iid; aws ec2 stop-instances --instance-ids "$iid" ;;
  4) aws ec2 describe-instance-status --output table ;;
  5) return ;;
  *) echo "❌ Invalid option." ;;
esac
