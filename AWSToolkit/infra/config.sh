#!/bin/bash
# AWS Config — Compliance & Rules

echo "=========== Config Module ==========="
echo "1) List Config Rules"
echo "2) Describe Compliance"
echo "3) Describe Delivery Channels"
echo "4) Back"
read -e -p "Select option [1-4]: " cfgopt

case $cfgopt in
  1) aws configservice describe-config-rules ;;
  2) read -e -p "Rule name: " name; aws configservice get-compliance-details-by-config-rule --config-rule-name "$name" ;;
  3) aws configservice describe-delivery-channels ;;
  4) return ;;
  *) echo "❌ Invalid option." ;;
esac
