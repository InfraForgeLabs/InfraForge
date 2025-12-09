#!/bin/bash
# Route53 — DNS Management

echo "=========== Route53 Module ==========="
echo "1) List Hosted Zones"
echo "2) List Record Sets"
echo "3) Create Record Set (from JSON)"
echo "4) Back"
read -e -p "Select option [1-4]: " r53opt

case $r53opt in
  1) aws route53 list-hosted-zones ;;
  2) read -e -p "Hosted Zone ID: " zone; aws route53 list-resource-record-sets --hosted-zone-id "$zone" ;;
  3) read -e -p "Hosted Zone ID: " zone; read -e -p "Change batch file (record.json): " file; aws route53 change-resource-record-sets --hosted-zone-id "$zone" --change-batch file://"$file" ;;
  4) return ;;
  *) echo "❌ Invalid option." ;;
esac
