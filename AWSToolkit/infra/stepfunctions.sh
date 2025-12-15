#!/bin/bash
# Step Functions — Workflow Automation

echo "=========== Step Functions Module ==========="
echo "1) List State Machines"
echo "2) Start Execution"
echo "3) Describe Execution"
echo "4) Back"
read -e -p "Select option [1-4]: " sfopt

case $sfopt in
  1) aws stepfunctions list-state-machines ;;
  2) read -e -p "State machine ARN: " arn; aws stepfunctions start-execution --state-machine-arn "$arn" ;;
  3) read -e -p "Execution ARN: " arn; aws stepfunctions describe-execution --execution-arn "$arn" ;;
  4) return ;;
  *) echo "❌ Invalid option." ;;
esac
