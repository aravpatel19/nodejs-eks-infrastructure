#!/bin/bash

echo "🚀 Deploying Full EKS + EC2 + RDS Infrastructure"
echo "================================================="
echo "⏱️  Estimated time: 10-15 minutes"
echo "💰 Estimated cost: ~$127/month"
echo ""

# Check if AWS CLI is configured
if ! aws sts get-caller-identity >/dev/null 2>&1; then
    echo "❌ AWS CLI not configured. Please run 'aws configure' first."
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl not found. Please install kubectl first."
    exit 1
fi

echo "📋 Pre-deployment checklist:"
echo "✅ AWS CLI configured"
echo "✅ kubectl installed"
echo ""

# Deploy main infrastructure (EC2 + RDS + S3)
echo "🏗️  Step 1/3: Deploying EC2 + RDS + S3 infrastructure..."
cd terraform
terraform init
terraform apply -auto-approve

if [ $? -ne 0 ]; then
    echo "❌ Failed to deploy main infrastructure"
    exit 1
fi

echo "✅ Main infrastructure deployed successfully!"
echo ""

# Deploy EKS cluster
echo "☸️  Step 2/3: Deploying EKS cluster..."
cd eks
terraform init
terraform apply -auto-approve

if [ $? -ne 0 ]; then
    echo "❌ Failed to deploy EKS cluster"
    exit 1
fi

echo "✅ EKS cluster deployed successfully!"
echo ""

# Update kubeconfig and deploy application
echo "🚀 Step 3/3: Deploying Node.js application to EKS..."
aws eks update-kubeconfig --region us-east-1 --name nodejs-eks-cluster

# Create namespace
kubectl create namespace nodejs-app --dry-run=client -o yaml | kubectl apply -f -

# Deploy application
kubectl apply -f ../k8s-manifests/

echo ""
echo "⏳ Waiting for application to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/nodejs-app -n nodejs-app

# Get the load balancer URL
echo ""
echo "🎉 Deployment Complete!"
echo "======================"
echo "📊 Infrastructure deployed:"
echo "  • EKS Cluster: 1x t3.small worker node"
echo "  • EC2 Instance: t2.micro"
echo "  • RDS Database: db.t2.micro"
echo "  • S3 Bucket: Static assets"
echo ""

# Get application URL
LOAD_BALANCER_URL=$(kubectl get service nodejs-service -n nodejs-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
if [ -n "$LOAD_BALANCER_URL" ]; then
    echo "🌐 Application URL: http://$LOAD_BALANCER_URL"
else
    echo "⏳ Load balancer is still provisioning. Check with:"
    echo "   kubectl get service nodejs-service -n nodejs-app"
fi

echo ""
echo "🔧 Useful commands:"
echo "  • Check pods: kubectl get pods -n nodejs-app"
echo "  • Check services: kubectl get services -n nodejs-app"
echo "  • View logs: kubectl logs -f deployment/nodejs-app -n nodejs-app"
echo "  • Scale app: kubectl scale deployment nodejs-app --replicas=3 -n nodejs-app"
echo ""
echo "💰 Current monthly cost: ~$127"
echo "🛑 To destroy: ./destroy-all.sh"
