#!/bin/bash

echo "🚀 Quick Demo Startup Script"
echo "=============================="

# Check if EC2 is running
echo "📡 Checking EC2 status..."
EC2_STATUS=$(aws ec2 describe-instances --instance-ids i-01735a0e4424afbe6 --query 'Reservations[0].Instances[0].State.Name' --output text 2>/dev/null)

if [ "$EC2_STATUS" = "running" ]; then
    echo "✅ EC2 is already running!"
    EC2_IP=$(aws ec2 describe-instances --instance-ids i-01735a0e4424afbe6 --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
    echo "🌐 App URL: http://$EC2_IP:3000"
else
    echo "🔄 Starting EC2 instance..."
    aws ec2 start-instances --instance-ids i-01735a0e4424afbe6
    echo "⏳ Waiting for EC2 to start (2-3 minutes)..."
    aws ec2 wait instance-running --instance-ids i-01735a0e4424afbe6
    EC2_IP=$(aws ec2 describe-instances --instance-ids i-01735a0e4424afbe6 --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
    echo "✅ EC2 started!"
    echo "🌐 App URL: http://$EC2_IP:3000"
fi

echo ""
echo "📊 Current Monthly Costs:"
echo "  - EC2 t2.micro: \$8.50"
echo "  - RDS db.t3.micro: \$12.50"
echo "  - S3: ~\$1-2"
echo "  - Total: ~\$22/month"
echo ""
echo "🎯 To stop and save money:"
echo "  aws ec2 stop-instances --instance-ids i-01735a0e4424afbe6"
