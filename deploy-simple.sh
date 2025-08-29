#!/bin/bash

echo "🚀 Deploying Simple EC2 + RDS Infrastructure"
echo "============================================="
echo "⏱️  Estimated time: 3-5 minutes"
echo "💰 Estimated cost: ~$17/month"
echo ""

# Check if AWS CLI is configured
if ! aws sts get-caller-identity >/dev/null 2>&1; then
    echo "❌ AWS CLI not configured. Please run 'aws configure' first."
    exit 1
fi

echo "📋 Pre-deployment checklist:"
echo "✅ AWS CLI configured"
echo ""

# Deploy infrastructure (EC2 + RDS + S3)
echo "🏗️  Deploying EC2 + RDS + S3 infrastructure..."
cd terraform
terraform init
terraform apply -auto-approve

if [ $? -ne 0 ]; then
    echo "❌ Failed to deploy infrastructure"
    exit 1
fi

echo ""
echo "🎉 Deployment Complete!"
echo "======================"
echo "📊 Infrastructure deployed:"
echo "  • EC2 Instance: t2.micro (Node.js app)"
echo "  • RDS Database: db.t2.micro (MySQL)"
echo "  • S3 Bucket: Static assets"
echo ""

# Get EC2 public IP
EC2_IP=$(terraform output -raw ec2_public_ip | cut -d'@' -f2)
echo "🌐 Application URL: http://$EC2_IP:3000"
echo ""

echo "🔧 Useful commands:"
echo "  • SSH to EC2: terraform output ec2_public_ip"
echo "  • Check EC2 status: aws ec2 describe-instances --instance-ids \$(terraform output -raw ec2_instance_id)"
echo "  • View app logs: ssh -i ~/.ssh/terraform-ec2.pem ubuntu@$EC2_IP 'sudo journalctl -u nodejs-app -f'"
echo ""
echo "💰 Current monthly cost: ~$17"
echo "🛑 To destroy: ./destroy-simple.sh"
