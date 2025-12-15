#!/bin/bash
# RDS Module — Database Management

echo "=========== RDS Module ==========="
echo "1) List DB Instances"
echo "2) Create DB Instance"
echo "3) Delete DB Instance"
echo "4) Back"
read -e -p "Select option [1-4]: " rdsopt

case $rdsopt in
  1) aws rds describe-db-instances ;;
  2) read -e -p "Enter DB ID: " id; aws rds create-db-instance --db-instance-identifier "$id" --db-instance-class db.t3.micro --engine mysql --master-username admin --master-user-password MyPass123 --allocated-storage 20 ;;
  3) read -e -p "Enter DB ID: " id; aws rds delete-db-instance --db-instance-identifier "$id" --skip-final-snapshot ;;
  4) return ;;
  *) echo "❌ Invalid option." ;;
esac
