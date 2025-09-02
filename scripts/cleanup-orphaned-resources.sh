#!/bin/bash

echo "🧹 Comprehensive AWS Resource Cleanup"
echo "===================================="
echo "🔍 This script will find and destroy orphaned resources"
echo ""

# Set AWS region
export AWS_REGION=us-east-1

echo "📋 Step 1: Checking for orphaned VPCs..."
VPC_IDS=$(aws ec2 describe-vpcs --query 'Vpcs[?IsDefault==`false`].[VpcId]' --output text 2>/dev/null)

if [ -n "$VPC_IDS" ]; then
    echo "Found VPCs: $VPC_IDS"
    
    for VPC_ID in $VPC_IDS; do
        echo "🗑️  Cleaning up VPC: $VPC_ID"
        
        # Delete NAT Gateways
        NAT_GATEWAYS=$(aws ec2 describe-nat-gateways --query "NatGateways[?VpcId=='$VPC_ID'].[NatGatewayId]" --output text 2>/dev/null)
        for NAT_ID in $NAT_GATEWAYS; do
            echo "  Deleting NAT Gateway: $NAT_ID"
            aws ec2 delete-nat-gateway --nat-gateway-id $NAT_ID 2>/dev/null
        done
        
        # Wait for NAT gateways to be deleted
        if [ -n "$NAT_GATEWAYS" ]; then
            echo "  Waiting for NAT gateways to be deleted..."
            sleep 30
        fi
        
        # Delete Load Balancers
        LBS=$(aws elbv2 describe-load-balancers --query "LoadBalancers[?VpcId=='$VPC_ID'].[LoadBalancerArn]" --output text 2>/dev/null)
        for LB_ARN in $LBS; do
            echo "  Deleting Load Balancer: $LB_ARN"
            aws elbv2 delete-load-balancer --load-balancer-arn $LB_ARN 2>/dev/null
        done
        
        # Delete EC2 instances
        INSTANCES=$(aws ec2 describe-instances --filters "Name=vpc-id,Values=$VPC_ID" "Name=instance-state-name,Values=running,stopped" --query 'Reservations[*].Instances[*].[InstanceId]' --output text 2>/dev/null)
        for INSTANCE_ID in $INSTANCES; do
            echo "  Terminating EC2 Instance: $INSTANCE_ID"
            aws ec2 terminate-instances --instance-ids $INSTANCE_ID 2>/dev/null
        done
        
        # Delete RDS instances
        RDS_INSTANCES=$(aws rds describe-db-instances --query "DBInstances[?DBSubnetGroup.VpcId=='$VPC_ID'].[DBInstanceIdentifier]" --output text 2>/dev/null)
        for RDS_ID in $RDS_INSTANCES; do
            echo "  Deleting RDS Instance: $RDS_ID"
            aws rds delete-db-instance --db-instance-identifier $RDS_ID --skip-final-snapshot 2>/dev/null
        done
        
        # Delete EKS clusters
        EKS_CLUSTERS=$(aws eks list-clusters --query 'clusters[]' --output text 2>/dev/null)
        for CLUSTER_NAME in $EKS_CLUSTERS; do
            CLUSTER_VPC=$(aws eks describe-cluster --name $CLUSTER_NAME --query 'cluster.resourcesVpcConfig.vpcId' --output text 2>/dev/null)
            if [ "$CLUSTER_VPC" = "$VPC_ID" ]; then
                echo "  Deleting EKS Cluster: $CLUSTER_NAME"
                aws eks delete-cluster --name $CLUSTER_NAME 2>/dev/null
            fi
        done
        
        # Delete Security Groups (except default)
        SGS=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" "Name=group-name,Values=!default" --query 'SecurityGroups[*].[GroupId]' --output text 2>/dev/null)
        for SG_ID in $SGS; do
            echo "  Deleting Security Group: $SG_ID"
            aws ec2 delete-security-group --group-id $SG_ID 2>/dev/null
        done
        
        # Delete Subnets
        SUBNETS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[*].[SubnetId]' --output text 2>/dev/null)
        for SUBNET_ID in $SUBNETS; do
            echo "  Deleting Subnet: $SUBNET_ID"
            aws ec2 delete-subnet --subnet-id $SUBNET_ID 2>/dev/null
        done
        
        # Delete Route Tables (except main)
        ROUTE_TABLES=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" "Name=association.main,Values=false" --query 'RouteTables[*].[RouteTableId]' --output text 2>/dev/null)
        for RT_ID in $ROUTE_TABLES; do
            echo "  Deleting Route Table: $RT_ID"
            aws ec2 delete-route-table --route-table-id $RT_ID 2>/dev/null
        done
        
        # Delete Internet Gateways
        IGW=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query 'InternetGateways[*].[InternetGatewayId]' --output text 2>/dev/null)
        if [ -n "$IGW" ]; then
            echo "  Detaching and deleting Internet Gateway: $IGW"
            aws ec2 detach-internet-gateway --internet-gateway-id $IGW --vpc-id $VPC_ID 2>/dev/null
            aws ec2 delete-internet-gateway --internet-gateway-id $IGW 2>/dev/null
        fi
        
        # Finally delete the VPC
        echo "  Deleting VPC: $VPC_ID"
        aws ec2 delete-vpc --vpc-id $VPC_ID 2>/dev/null
        
        echo "✅ VPC $VPC_ID cleanup completed"
    done
else
    echo "✅ No orphaned VPCs found"
fi

echo ""
echo "📋 Step 2: Checking for orphaned EBS volumes..."
EBS_VOLUMES=$(aws ec2 describe-volumes --filters "Name=status,Values=available" --query 'Volumes[*].[VolumeId]' --output text 2>/dev/null)
if [ -n "$EBS_VOLUMES" ]; then
    echo "Found orphaned EBS volumes: $EBS_VOLUMES"
    for VOLUME_ID in $EBS_VOLUMES; do
        echo "  Deleting EBS Volume: $VOLUME_ID"
        aws ec2 delete-volume --volume-id $VOLUME_ID 2>/dev/null
    done
else
    echo "✅ No orphaned EBS volumes found"
fi

echo ""
echo "📋 Step 3: Checking for orphaned Elastic IPs..."
EIPS=$(aws ec2 describe-addresses --query 'Addresses[?AssociationId==null].[AllocationId]' --output text 2>/dev/null)
if [ -n "$EIPS" ]; then
    echo "Found orphaned Elastic IPs: $EIPS"
    for EIP_ID in $EIPS; do
        echo "  Releasing Elastic IP: $EIP_ID"
        aws ec2 release-address --allocation-id $EIP_ID 2>/dev/null
    done
else
    echo "✅ No orphaned Elastic IPs found"
fi

echo ""
echo "📋 Step 4: Checking for orphaned S3 buckets..."
S3_BUCKETS=$(aws s3api list-buckets --query 'Buckets[?contains(Name, `terraform`) || contains(Name, `eks`) || contains(Name, `nodejs`)].Name' --output text 2>/dev/null)
if [ -n "$S3_BUCKETS" ]; then
    echo "Found potential orphaned S3 buckets: $S3_BUCKETS"
    for BUCKET_NAME in $S3_BUCKETS; do
        echo "  Deleting S3 bucket: $BUCKET_NAME"
        aws s3 rb s3://$BUCKET_NAME --force 2>/dev/null
    done
else
    echo "✅ No orphaned S3 buckets found"
fi

echo ""
echo "📋 Step 5: Checking for orphaned IAM roles..."
IAM_ROLES=$(aws iam list-roles --query 'Roles[?contains(RoleName, `eks`) || contains(RoleName, `terraform`)].RoleName' --output text 2>/dev/null)
if [ -n "$IAM_ROLES" ]; then
    echo "Found potential orphaned IAM roles: $IAM_ROLES"
    for ROLE_NAME in $IAM_ROLES; do
        echo "  Deleting IAM role: $ROLE_NAME"
        # Detach policies first
        POLICIES=$(aws iam list-attached-role-policies --role-name $ROLE_NAME --query 'AttachedPolicies[*].PolicyArn' --output text 2>/dev/null)
        for POLICY_ARN in $POLICIES; do
            aws iam detach-role-policy --role-name $ROLE_NAME --policy-arn $POLICY_ARN 2>/dev/null
        done
        # Delete the role
        aws iam delete-role --role-name $ROLE_NAME 2>/dev/null
    done
else
    echo "✅ No orphaned IAM roles found"
fi

echo ""
echo "✅ Cleanup completed!"
echo "💰 Your AWS charges should now be $0/month"
echo ""
echo "🚀 To redeploy:"
echo "  • Full EKS setup: ./deploy-full-eks.sh"
echo "  • Simple setup: ./deploy-simple.sh"
