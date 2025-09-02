#!/bin/bash

echo "🔍 Deployment Verification Script"
echo "================================="
echo "This script will verify that your deployment scripts work correctly"
echo ""

# Function to check if AWS CLI is configured
check_aws_cli() {
    if ! aws sts get-caller-identity >/dev/null 2>&1; then
        echo "❌ AWS CLI not configured. Please run 'aws configure' first."
        return 1
    fi
    echo "✅ AWS CLI configured"
    return 0
}

# Function to check if kubectl is installed
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        echo "❌ kubectl not found. Please install kubectl first."
        return 1
    fi
    echo "✅ kubectl installed"
    return 0
}

# Function to check Terraform files
check_terraform_files() {
    echo "📋 Checking Terraform configuration..."
    
    # Check if main terraform files exist
    if [ ! -f "terraform/variables.tf" ]; then
        echo "❌ terraform/variables.tf not found"
        return 1
    fi
    
    if [ ! -f "terraform/ec2.tf" ]; then
        echo "❌ terraform/ec2.tf not found"
        return 1
    fi
    
    if [ ! -f "terraform/rds.tf" ]; then
        echo "❌ terraform/rds.tf not found"
        return 1
    fi
    
    if [ ! -f "terraform/vpc.tf" ]; then
        echo "❌ terraform/vpc.tf not found"
        return 1
    fi
    
    if [ ! -f "terraform/s3.tf" ]; then
        echo "❌ terraform/s3.tf not found"
        return 1
    fi
    
    # Check if EKS terraform files exist
    if [ ! -f "terraform/eks/main.tf" ]; then
        echo "❌ terraform/eks/main.tf not found"
        return 1
    fi
    
    if [ ! -f "terraform/eks/vpc.tf" ]; then
        echo "❌ terraform/eks/vpc.tf not found"
        return 1
    fi
    
    if [ ! -f "terraform/eks/node-groups.tf" ]; then
        echo "❌ terraform/eks/node-groups.tf not found"
        return 1
    fi
    
    echo "✅ All Terraform files found"
    return 0
}

# Function to check Kubernetes manifests
check_k8s_manifests() {
    echo "📋 Checking Kubernetes manifests..."
    
    if [ ! -f "terraform/k8s-manifests/namespace.yaml" ]; then
        echo "❌ terraform/k8s-manifests/namespace.yaml not found"
        return 1
    fi
    
    if [ ! -f "terraform/k8s-manifests/deployment.yaml" ]; then
        echo "❌ terraform/k8s-manifests/deployment.yaml not found"
        return 1
    fi
    
    if [ ! -f "terraform/k8s-manifests/service.yaml" ]; then
        echo "❌ terraform/k8s-manifests/service.yaml not found"
        return 1
    fi
    
    if [ ! -f "terraform/k8s-manifests/configmap.yaml" ]; then
        echo "❌ terraform/k8s-manifests/configmap.yaml not found"
        return 1
    fi
    
    if [ ! -f "terraform/k8s-manifests/secret.yaml" ]; then
        echo "❌ terraform/k8s-manifests/secret.yaml not found"
        return 1
    fi
    
    echo "✅ All Kubernetes manifests found"
    return 0
}

# Function to check deployment scripts
check_deployment_scripts() {
    echo "📋 Checking deployment scripts..."
    
    if [ ! -f "scripts/deploy-simple.sh" ]; then
        echo "❌ scripts/deploy-simple.sh not found"
        return 1
    fi
    
    if [ ! -f "scripts/deploy-full-eks.sh" ]; then
        echo "❌ scripts/deploy-full-eks.sh not found"
        return 1
    fi
    
    if [ ! -f "scripts/destroy-simple.sh" ]; then
        echo "❌ scripts/destroy-simple.sh not found"
        return 1
    fi
    
    if [ ! -f "scripts/destroy-all.sh" ]; then
        echo "❌ scripts/destroy-all.sh not found"
        return 1
    fi
    
    if [ ! -f "scripts/cleanup-orphaned-resources.sh" ]; then
        echo "❌ scripts/cleanup-orphaned-resources.sh not found"
        return 1
    fi
    
    # Make scripts executable
    chmod +x scripts/*.sh
    
    echo "✅ All deployment scripts found and made executable"
    return 0
}

# Function to check app files
check_app_files() {
    echo "📋 Checking application files..."
    
    if [ ! -f "app/package.json" ]; then
        echo "❌ app/package.json not found"
        return 1
    fi
    
    if [ ! -f "app/server.js" ]; then
        echo "❌ app/server.js not found"
        return 1
    fi
    
    if [ ! -f "app/Dockerfile" ]; then
        echo "❌ app/Dockerfile not found"
        return 1
    fi
    
    echo "✅ All application files found"
    return 0
}

# Function to run Terraform validation
validate_terraform() {
    echo "📋 Validating Terraform configurations..."
    
    # Validate main terraform
    cd terraform
    if ! terraform init -backend=false >/dev/null 2>&1; then
        echo "❌ terraform init failed"
        cd ..
        return 1
    fi
    
    if ! terraform validate >/dev/null 2>&1; then
        echo "❌ terraform validate failed"
        cd ..
        return 1
    fi
    
    cd ..
    
    # Validate EKS terraform
    cd terraform/eks
    if ! terraform init -backend=false >/dev/null 2>&1; then
        echo "❌ EKS terraform init failed"
        cd ../..
        return 1
    fi
    
    if ! terraform validate >/dev/null 2>&1; then
        echo "❌ EKS terraform validate failed"
        cd ../..
        return 1
    fi
    
    cd ../..
    
    echo "✅ All Terraform configurations are valid"
    return 0
}

# Main verification
echo "🔍 Starting comprehensive verification..."
echo ""

# Run all checks
errors=0

check_aws_cli || ((errors++))
check_kubectl || ((errors++))
check_terraform_files || ((errors++))
check_k8s_manifests || ((errors++))
check_deployment_scripts || ((errors++))
check_app_files || ((errors++))
validate_terraform || ((errors++))

echo ""
echo "📊 Verification Results:"
echo "======================="

if [ $errors -eq 0 ]; then
    echo "✅ All checks passed! Your deployment setup is ready."
    echo ""
    echo "🚀 You can now deploy using:"
    echo "  • Simple setup: ./scripts/deploy-simple.sh"
    echo "  • Full EKS setup: ./scripts/deploy-full-eks.sh"
    echo ""
    echo "🛑 To clean up:"
    echo "  • Simple cleanup: ./scripts/destroy-simple.sh"
    echo "  • Full cleanup: ./scripts/destroy-all.sh"
    echo "  • Orphaned resources: ./scripts/cleanup-orphaned-resources.sh"
else
    echo "❌ Found $errors error(s). Please fix them before deploying."
    echo ""
    echo "💡 Common fixes:"
    echo "  • Run 'aws configure' to set up AWS CLI"
    echo "  • Install kubectl: brew install kubectl (macOS) or follow official docs"
    echo "  • Check that all files are in the correct locations"
fi
