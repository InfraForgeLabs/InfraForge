#!/bin/bash
# CloudFront — CDN Distribution

echo "=========== CloudFront Module ==========="
echo "1) List Distributions"
echo "2) Create Distribution"
echo "3) Create Invalidation"
echo "4) Back"
read -e -p "Select option [1-4]: " cfopt

case $cfopt in
  1) aws cloudfront list-distributions ;;
  2) read -e -p "Origin domain name (e.g. mybucket.s3.amazonaws.com): " origin; aws cloudfront create-distribution --origin-domain-name "$origin" ;;
  3) read -e -p "Distribution ID: " id; read -e -p "Paths (e.g. /*): " paths; aws cloudfront create-invalidation --distribution-id "$id" --paths "$paths" ;;
  4) return ;;
  *) echo "❌ Invalid option." ;;
esac
