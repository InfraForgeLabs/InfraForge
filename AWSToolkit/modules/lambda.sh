#!/bin/bash
# Lambda Module — Manage Serverless Functions

echo "=========== Lambda Module ==========="
echo "1) List Functions"
echo "2) Invoke Function"
echo "3) Update Code"
echo "4) Create Function"
echo "5) Back"
read -e -p "Select option [1-5]: " lambdaopt

case $lambdaopt in
  1) aws lambda list-functions ;;
  2) read -e -p "Enter Function Name: " fn; aws lambda invoke --function-name "$fn" output.json; cat output.json ;;
  3) read -e -p "Enter Function Name: " fn; read -e -p "ZIP file path: " zip; aws lambda update-function-code --function-name "$fn" --zip-file fileb://"$zip" ;;
  4) echo "💡 Create Lambda with --zip-file, --role, and --handler manually via AWS CLI." ;;
  5) return ;;
  *) echo "❌ Invalid option." ;;
esac
