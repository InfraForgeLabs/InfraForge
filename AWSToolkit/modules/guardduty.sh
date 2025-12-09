#!/bin/bash
# GuardDuty Module — Security Findings

echo "=========== GuardDuty Module ==========="
echo "1) List Detectors"
echo "2) List Findings"
echo "3) Back"
read -e -p "Select option [1-3]: " gdopt

case $gdopt in
  1) aws guardduty list-detectors ;;
  2) aws guardduty list-findings ;;
  3) return ;;
  *) echo "❌ Invalid option." ;;
esac

