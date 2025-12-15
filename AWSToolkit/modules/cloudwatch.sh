#!/bin/bash
# CloudWatch Module — Monitoring and Logs

echo "=========== CloudWatch Module ==========="
echo "1) List Metrics"
echo "2) View Lambda Logs"
echo "3) Get CPU Utilization"
echo "4) Back"
read -e -p "Select option [1-4]: " cwopt

case $cwopt in
  1) aws cloudwatch list-metrics ;;
  2) read -e -p "Enter Log Group: " group; aws logs describe-log-streams --log-group-name "$group" ;;
  3) read -e -p "Enter Instance ID: " id; aws cloudwatch get-metric-statistics --namespace AWS/EC2 --metric-name CPUUtilization --dimensions Name=InstanceId,Value="$id" --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ) --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) --period 300 --statistics Average ;;
  4) return ;;
  *) echo "❌ Invalid option." ;;
esac
