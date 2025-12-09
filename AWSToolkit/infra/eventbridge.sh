#!/bin/bash
# EventBridge — Event-driven Rules

echo "=========== EventBridge Module ==========="
echo "1) List Rules"
echo "2) Create Rule"
echo "3) List Targets by Rule"
echo "4) Back"
read -e -p "Select option [1-4]: " ebopt

case $ebopt in
  1) aws events list-rules ;;
  2) read -e -p "Rule name: " name; read -e -p "Schedule (e.g. rate(1 hour)): " sched; aws events put-rule --name "$name" --schedule-expression "$sched" ;;
  3) read -e -p "Rule name: " name; aws events list-targets-by-rule --rule "$name" ;;
  4) return ;;
  *) echo "❌ Invalid option." ;;
esac
