#!/bin/bash

echo "📊 Project Status Dashboard"
echo "=========================="
echo ""

# Check AWS CLI
if aws sts get-caller-identity >/dev/null 2>&1; then
    echo "✅ AWS CLI: Configured"
    AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
    echo "   Account: $AWS_ACCOUNT"
else
    echo "❌ AWS CLI: Not configured"
fi

echo ""

# Check for running resources
echo "🔍 Checking for running resources..."

# Check EC2 instances
EC2_COUNT=$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" --query 'length(Reservations[].Instances[])')
if [ "$EC2_COUNT" -gt 0 ]; then
    echo "⚠️  EC2 Instances: $EC2_COUNT running"
    aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" --query 'Reservations[].Instances[].[InstanceId,InstanceType,State.Name,PublicIpAddress]' --output table
else
    echo "✅ EC2 Instances: None running"
fi

# Check RDS instances
RDS_COUNT=$(aws rds describe-db-instances --query 'length(DBInstances)')
if [ "$RDS_COUNT" -gt 0 ]; then
    echo "⚠️  RDS Instances: $RDS_COUNT running"
    aws rds describe-db-instances --query 'DBInstances[].[DBInstanceIdentifier,DBInstanceClass,DBInstanceStatus]' --output table
else
    echo "✅ RDS Instances: None running"
fi

# Check EKS clusters
EKS_COUNT=$(aws eks list-clusters --query 'length(clusters)')
if [ "$EKS_COUNT" -gt 0 ]; then
    echo "⚠️  EKS Clusters: $EKS_COUNT running"
    aws eks list-clusters --query 'clusters[]' --output table
else
    echo "✅ EKS Clusters: None running"
fi

# Check Load Balancers
LB_COUNT=$(aws elbv2 describe-load-balancers --query 'length(LoadBalancers)')
if [ "$LB_COUNT" -gt 0 ]; then
    echo "⚠️  Load Balancers: $LB_COUNT running"
    aws elbv2 describe-load-balancers --query 'LoadBalancers[].[LoadBalancerName,State.Code]' --output table
else
    echo "✅ Load Balancers: None running"
fi

echo ""
echo "💰 Estimated Monthly Cost: \$0"
echo ""

# Show available scripts
echo "🚀 Available Commands:"
echo "  • ./deploy-simple.sh     - Deploy simple setup (~\$17/month)"
echo "  • ./deploy-full-eks.sh   - Deploy full EKS setup (~\$127/month)"
echo "  • ./destroy-all.sh       - Destroy everything (save money)"
echo "  • ./status.sh            - Show this status"
echo ""

if [ "$EC2_COUNT" -gt 0 ] || [ "$RDS_COUNT" -gt 0 ] || [ "$EKS_COUNT" -gt 0 ]; then
    echo "⚠️  You have running resources that are costing money!"
    echo "   Run ./destroy-all.sh to stop all costs"
else
    echo "✅ No running resources - you're at \$0 cost!"
fi
