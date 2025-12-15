#!/bin/bash
# DynamoDB — NoSQL Tables

echo "=========== DynamoDB Module ==========="
echo "1) List Tables"
echo "2) Scan Table"
echo "3) Put Item"
echo "4) Delete Item"
echo "5) Back"
read -e -p "Select option [1-5]: " ddbopt

case $ddbopt in
  1) aws dynamodb list-tables ;;
  2) read -e -p "Table name: " tbl; aws dynamodb scan --table-name "$tbl" ;;
  3) read -e -p "Table name: " tbl; read -e -p "Item JSON: " item; aws dynamodb put-item --table-name "$tbl" --item "$item" ;;
  4) read -e -p "Table name: " tbl; read -e -p "Key JSON: " key; aws dynamodb delete-item --table-name "$tbl" --key "$key" ;;
  5) return ;;
  *) echo "❌ Invalid option." ;;
esac
