#!/bin/bash

echo "🛑 Destroying All Infrastructure"
echo "==============================="
echo "⚠️  This will destroy ALL resources and set cost to $0"
echo ""

read -p "Are you sure you want to destroy everything? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "❌ Destruction cancelled"
    exit 1
fi

echo "🗑️  Step 1/2: Destroying EKS cluster..."
cd terraform/eks
terraform destroy -auto-approve

echo ""
echo "🗑️  Step 2/2: Destroying EC2 + RDS + S3..."
cd ..
terraform destroy -auto-approve

echo ""
echo "✅ All infrastructure destroyed!"
echo "💰 Current cost: $0/month"
echo ""
echo "🚀 To redeploy:"
echo "  • Full EKS setup: ./deploy-full-eks.sh"
echo "  • Simple setup: ./deploy-simple.sh"
