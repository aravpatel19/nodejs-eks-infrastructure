# 🚀 Deployment Guide

This guide explains how to deploy your Node.js application using the automated scripts.

## 📊 Current Status: $0 Cost ✅

All infrastructure has been destroyed to save money. Use the deployment scripts to bring back what you need.

## 🎯 Deployment Options

### **Option 1: Simple Setup (Recommended for Learning)**
```bash
./deploy-simple.sh
```

**What it deploys:**
- EC2 t2.micro instance (Node.js app)
- RDS db.t2.micro (MySQL database)
- S3 bucket (static assets)

**Cost:** ~$17/month
**Time:** 3-5 minutes
**Best for:** Learning, demos, portfolio projects

### **Option 2: Full EKS Setup (Enterprise-Grade)**
```bash
./deploy-full-eks.sh
```

**What it deploys:**
- EKS cluster with 1x t3.small worker node
- Load balancer for public access
- EC2 t2.micro instance
- RDS db.t2.micro (MySQL database)
- S3 bucket (static assets)
- Kubernetes manifests (deployment, service, configmap, secret)

**Cost:** ~$127/month
**Time:** 10-15 minutes
**Best for:** Enterprise demos, showcasing Kubernetes skills

## 🛑 Destroying Infrastructure

### **Destroy Everything**
```bash
./destroy-all.sh
```
Destroys all infrastructure and sets cost to $0.

### **Destroy Simple Setup Only**
```bash
./destroy-simple.sh
```
Destroys only the simple EC2+RDS setup.

## 📊 Check Status

```bash
./status.sh
```
Shows current AWS resources and estimated costs.

## 🔧 Prerequisites

Before running any deployment script:

1. **AWS CLI configured:**
   ```bash
   aws configure
   ```

2. **For EKS deployment, kubectl installed:**
   ```bash
   # macOS
   brew install kubectl
   
   # Or download from: https://kubernetes.io/docs/tasks/tools/
   ```

## 🎯 Demo Scenarios

### **Quick Demo (5 minutes)**
1. Run `./deploy-simple.sh`
2. Wait for completion
3. Access app via provided URL
4. Run `./destroy-simple.sh` when done

### **Enterprise Demo (15 minutes)**
1. Run `./deploy-full-eks.sh`
2. Wait for EKS cluster to be ready
3. Access app via load balancer URL
4. Show Kubernetes features:
   ```bash
   kubectl get pods -n nodejs-app
   kubectl get services -n nodejs-app
   kubectl scale deployment nodejs-app --replicas=3 -n nodejs-app
   ```
5. Run `./destroy-all.sh` when done

## 💰 Cost Management

### **Current Optimization:**
- **Both setups use t2.micro instances** for consistency
- **RDS uses db.t2.micro** (not db.t3.micro) to match EC2
- **No NAT Gateways** in EKS setup (saves $45/month)
- **Destroy when not needed** - easy to recreate

### **Cost Breakdown:**
- **Simple Setup:** $17/month (EC2 + RDS + S3)
- **Full EKS Setup:** $127/month (EKS + Load Balancer + EC2 + RDS + S3)
- **Current Status:** $0/month (everything destroyed)

## 🚨 Important Notes

1. **Always destroy when done** - AWS resources cost money even when idle
2. **EKS is expensive** - only use for enterprise demos
3. **Simple setup is sufficient** for most learning and portfolio purposes
4. **Scripts handle all the complexity** - no manual Terraform commands needed

## 🎓 Learning Outcomes

This project demonstrates:
- **Infrastructure as Code** (Terraform)
- **Container Orchestration** (Kubernetes)
- **Cloud Architecture** (AWS services)
- **DevOps Automation** (deployment scripts)
- **Cost Optimization** (right-sizing resources)

Perfect for showcasing comprehensive DevOps and cloud engineering skills! 🚀
