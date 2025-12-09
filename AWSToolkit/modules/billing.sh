#!/bin/bash
# Billing Module — Cost Explorer API

echo "=========== Billing Module ==========="
echo "1) Get Daily Cost"
echo "2) Get Monthly Cost"
echo "3) Back"
read -e -p "Select option [1-3]: " billopt

case $billopt in
  1) aws ce get-cost-and-usage --time-period Start=$(date -d '1 day ago' +%Y-%m-%d),End=$(date +%Y-%m-%d) --granularity DAILY --metrics "UnblendedCost" ;;
  2) aws ce get-cost-and-usage --time-period Start=$(date -d '1 month ago' +%Y-%m-%d),End=$(date +%Y-%m-%d) --granularity MONTHLY --metrics "UnblendedCost" ;;
  3) return ;;
  *) echo "❌ Invalid option." ;;
esac
