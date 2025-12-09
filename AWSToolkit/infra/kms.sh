#!/bin/bash
# KMS — Key Management Service

echo "=========== KMS Module ==========="
echo "1) List Keys"
echo "2) Create Key"
echo "3) Describe Key"
echo "4) Enable Key Rotation"
echo "5) Back"
read -e -p "Select option [1-5]: " kmsopt

case $kmsopt in
  1) aws kms list-keys ;;
  2) read -e -p "Description: " desc; aws kms create-key --description "$desc" ;;
  3) read -e -p "Key ID or Alias: " id; aws kms describe-key --key-id "$id" ;;
  4) read -e -p "Key ID: " id; aws kms enable-key-rotation --key-id "$id" ;;
  5) return ;;
  *) echo "❌ Invalid option." ;;
esac
