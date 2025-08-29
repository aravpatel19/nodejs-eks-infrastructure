#!/bin/bash

echo "🛑 Destroying Simple Infrastructure"
echo "=================================="
echo "⚠️  This will destroy EC2 + RDS + S3 and set cost to $0"
echo ""

read -p "Are you sure you want to destroy the simple infrastructure? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "❌ Destruction cancelled"
    exit 1
fi

echo "🗑️  Destroying EC2 + RDS + S3..."
cd terraform
terraform destroy -auto-approve

echo ""
echo "✅ Simple infrastructure destroyed!"
echo "💰 Current cost: $0/month"
echo ""
echo "🚀 To redeploy:"
echo "  • Simple setup: ./deploy-simple.sh"
echo "  • Full EKS setup: ./deploy-full-eks.sh"
