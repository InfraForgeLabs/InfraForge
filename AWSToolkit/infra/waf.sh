#!/bin/bash
# WAF — Web Application Firewall

echo "=========== WAF Module ==========="
echo "1) List Web ACLs"
echo "2) Get Web ACL"
echo "3) List IP Sets"
echo "4) Back"
read -e -p "Select option [1-4]: " wafopt

case $wafopt in
  1) aws wafv2 list-web-acls --scope REGIONAL ;;
  2) read -e -p "Web ACL ARN: " arn; aws wafv2 get-web-acl --name my-acl --scope REGIONAL --id "$arn" ;;
  3) aws wafv2 list-ip-sets --scope REGIONAL ;;
  4) return ;;
  *) echo "❌ Invalid option." ;;
esac
