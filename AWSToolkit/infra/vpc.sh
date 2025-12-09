#!/bin/bash
# VPC — Networking

echo "=========== VPC Module ==========="
echo "1) List VPCs"
echo "2) Create VPC"
echo "3) List Subnets"
echo "4) Describe Security Groups"
echo "5) Back"
read -e -p "Select option [1-5]: " vpcopt

case $vpcopt in
  1) aws ec2 describe-vpcs ;;
  2) read -e -p "CIDR block (e.g. 10.0.0.0/16): " cidr; aws ec2 create-vpc --cidr-block "$cidr" ;;
  3) aws ec2 describe-subnets ;;
  4) aws ec2 describe-security-groups ;;
  5) return ;;
  *) echo "❌ Invalid option." ;;
esac
