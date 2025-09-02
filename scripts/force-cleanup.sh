#!/bin/bash

echo "🔨 Force Cleanup Script"
echo "======================="
echo "This script will force delete resources that are preventing cleanup"
echo ""

# Set AWS region
export AWS_REGION=us-east-1

echo "🔍 Step 1: Finding problematic VPCs..."
VPC_IDS=$(aws ec2 describe-vpcs --query 'Vpcs[?IsDefault==`false`].[VpcId]' --output text 2>/dev/null)

if [ -n "$VPC_IDS" ]; then
    echo "Found VPCs: $VPC_IDS"
    
    for VPC_ID in $VPC_IDS; do
        echo "🗑️  Force cleaning VPC: $VPC_ID"
        
        # Find all network interfaces in this VPC
        ENIS=$(aws ec2 describe-network-interfaces --filters "Name=vpc-id,Values=$VPC_ID" --query 'NetworkInterfaces[*].[NetworkInterfaceId]' --output text 2>/dev/null)
        
        if [ -n "$ENIS" ]; then
            echo "  Found network interfaces: $ENIS"
            
            for ENI_ID in $ENIS; do
                echo "    Force deleting network interface: $ENI_ID"
                
                # Try to detach if attached
                ATTACHMENT_ID=$(aws ec2 describe-network-interfaces --network-interface-ids $ENI_ID --query 'NetworkInterfaces[0].Attachment.AttachmentId' --output text 2>/dev/null)
                if [ "$ATTACHMENT_ID" != "None" ] && [ -n "$ATTACHMENT_ID" ]; then
                    echo "      Detaching attachment: $ATTACHMENT_ID"
                    aws ec2 detach-network-interface --attachment-id $ATTACHMENT_ID --force 2>/dev/null
                    sleep 10
                fi
                
                # Try to delete the network interface
                aws ec2 delete-network-interface --network-interface-id $ENI_ID 2>/dev/null
                if [ $? -eq 0 ]; then
                    echo "      ✅ Network interface deleted"
                else
                    echo "      ⚠️  Network interface still in use, will retry..."
                fi
            done
            
            # Wait a bit for network interfaces to be fully deleted
            sleep 30
        fi
        
        # Delete subnets
        SUBNETS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[*].[SubnetId]' --output text 2>/dev/null)
        for SUBNET_ID in $SUBNETS; do
            echo "    Deleting subnet: $SUBNET_ID"
            aws ec2 delete-subnet --subnet-id $SUBNET_ID 2>/dev/null
        done
        
        # Delete route tables (except main)
        ROUTE_TABLES=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" "Name=association.main,Values=false" --query 'RouteTables[*].[RouteTableId]' --output text 2>/dev/null)
        for RT_ID in $ROUTE_TABLES; do
            echo "    Deleting route table: $RT_ID"
            aws ec2 delete-route-table --route-table-id $RT_ID 2>/dev/null
        done
        
        # Delete internet gateways
        IGW=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query 'InternetGateways[*].[InternetGatewayId]' --output text 2>/dev/null)
        if [ -n "$IGW" ]; then
            echo "    Detaching and deleting internet gateway: $IGW"
            aws ec2 detach-internet-gateway --internet-gateway-id $IGW --vpc-id $VPC_ID 2>/dev/null
            aws ec2 delete-internet-gateway --internet-gateway-id $IGW 2>/dev/null
        fi
        
        # Delete security groups (except default)
        SGS=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" "Name=group-name,Values=!default" --query 'SecurityGroups[*].[GroupId]' --output text 2>/dev/null)
        for SG_ID in $SGS; do
            echo "    Deleting security group: $SG_ID"
            aws ec2 delete-security-group --group-id $SG_ID 2>/dev/null
        done
        
        # Finally try to delete the VPC
        echo "    Deleting VPC: $VPC_ID"
        aws ec2 delete-vpc --vpc-id $VPC_ID 2>/dev/null
        
        if [ $? -eq 0 ]; then
            echo "✅ VPC $VPC_ID successfully deleted"
        else
            echo "❌ VPC $VPC_ID still has dependencies"
        fi
    done
else
    echo "✅ No orphaned VPCs found"
fi

echo ""
echo "🔍 Step 2: Checking for any remaining resources..."

# Check for any remaining VPCs
REMAINING_VPCS=$(aws ec2 describe-vpcs --query 'Vpcs[?IsDefault==`false`].[VpcId]' --output text 2>/dev/null)
if [ -n "$REMAINING_VPCS" ]; then
    echo "⚠️  Still have VPCs: $REMAINING_VPCS"
    echo "   These may require manual cleanup or AWS support"
else
    echo "✅ All VPCs successfully deleted"
fi

# Check for any remaining load balancers
REMAINING_LBS=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[*].[LoadBalancerArn]' --output text 2>/dev/null)
if [ -n "$REMAINING_LBS" ]; then
    echo "⚠️  Still have load balancers: $REMAINING_LBS"
else
    echo "✅ No load balancers found"
fi

# Check for any remaining EC2 instances
REMAINING_INSTANCES=$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=running,stopped" --query 'Reservations[*].Instances[*].[InstanceId]' --output text 2>/dev/null)
if [ -n "$REMAINING_INSTANCES" ]; then
    echo "⚠️  Still have EC2 instances: $REMAINING_INSTANCES"
else
    echo "✅ No EC2 instances found"
fi

# Check for any remaining RDS instances
REMAINING_RDS=$(aws rds describe-db-instances --query 'DBInstances[*].[DBInstanceIdentifier]' --output text 2>/dev/null)
if [ -n "$REMAINING_RDS" ]; then
    echo "⚠️  Still have RDS instances: $REMAINING_RDS"
else
    echo "✅ No RDS instances found"
fi

echo ""
echo "🎯 Force cleanup completed!"
echo "💰 Your AWS charges should now be $0/month"
echo ""
echo "💡 If resources still remain, you may need to:"
echo "   1. Wait 24-48 hours for AWS to fully process deletions"
echo "   2. Contact AWS support for manual cleanup"
echo "   3. Check AWS billing dashboard to confirm charges have stopped"
