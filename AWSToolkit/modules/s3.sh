#!/bin/bash
# S3 Module — Manage Buckets & Objects

echo "=========== S3 Module ==========="
echo "1) List Buckets"
echo "2) Upload File"
echo "3) Sync Folder"
echo "4) Remove Bucket"
echo "5) Back"
read -e -p "Select option [1-5]: " s3opt

case $s3opt in
  1) aws s3 ls ;;
  2) read -e -p "Enter file path: " file; read -e -p "Enter bucket: " bucket; aws s3 cp "$file" "s3://$bucket/" ;;
  3) read -e -p "Enter folder path: " folder; read -e -p "Enter bucket: " bucket; aws s3 sync "$folder" "s3://$bucket/" ;;
  4) read -e -p "Enter bucket name: " bucket; aws s3 rb "s3://$bucket" --force ;;
  5) return ;;
  *) echo "❌ Invalid option." ;;
esac
