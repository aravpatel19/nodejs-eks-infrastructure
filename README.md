# Node.js App with Full DevOps Pipeline

I built a comprehensive user management app with Node.js and MySQL, then deployed it on AWS using multiple approaches. The project now includes a complete CI/CD pipeline, multiple deployment methods, and professional repository structure using git submodules.

### 🚀 **Three Ways to Access the App:**

1. **Local Docker** (`localhost:3000`) - For local development with local MySQL
2. **EKS Port-Forward** (`localhost:8080`) - Local access to cloud deployment
3. **Public URL** - `http://af2297c2cfb804d858ad1ac92e392174-1808336492.us-east-1.elb.amazonaws.com`

### ✨ **Key Features:**

- **Full CRUD functionality** - Add, view, and delete users
- **CI/CD Pipeline** - Automatic deployment on code changes
- **Multiple deployment methods** - Docker, EKS, and public access
- **Professional repository structure** - Git submodules for clean separation
- **Auto port-forward script** - Seamless local development
- **Health checks** - Automated deployment verification

## Project Structure

```
06_project/
├── app/                          # Application code (git submodule)
│   ├── public/                   # Frontend files
│   ├── server.js                 # Node.js backend with CRUD APIs
│   ├── package.json              # Dependencies
│   ├── Dockerfile                # Container setup
│   └── .github/workflows/        # CI/CD pipeline
├── terraform/                    # Infrastructure as Code
│   ├── eks/                      # EKS cluster setup
│   │   ├── main.tf               # Cluster configuration
│   │   ├── vpc.tf                # VPC and networking
│   │   ├── node-groups.tf        # Worker nodes
│   │   └── outputs.tf            # Cluster outputs
│   ├── k8s-manifests/            # Kubernetes configurations
│   │   ├── namespace.yaml        # Application namespace
│   │   ├── deployment.yaml       # App deployment
│   │   ├── service.yaml          # Load balancer service
│   │   ├── configmap.yaml        # App configuration
│   │   └── secret.yaml           # Database credentials
│   ├── ec2.tf                    # EC2 configuration
│   ├── rds.tf                    # Database setup
│   ├── s3.tf                     # Storage bucket
│   └── variables.tf              # Terraform variables
├── auto-port-forward.sh          # Auto-restart port-forward script
└── README.md                     # This file
```

## What's in the App

It's a comprehensive user management system with full CRUD functionality:

**Frontend**: Modern HTML/CSS/JS interface with real-time updates
**Backend**: Express.js server with RESTful API endpoints
**Database**: RDS MySQL instance with proper data persistence

### 🔗 **API Endpoints:**

- `GET /` - Main application page
- `GET /users` - Returns all users (JSON)
- `POST /users` - Adds a new user
- `DELETE /users/:id` - Deletes a user by ID

### 🎨 **Frontend Features:**

- **Add User Form** - Name and email input with validation
- **User Table** - Displays all users with real-time updates
- **Delete Functionality** - Remove users with confirmation
- **Success/Error Messages** - User feedback for all operations
- **Responsive Design** - Works on desktop and mobile

The app demonstrates modern web development practices with a clean separation between frontend and backend.

## AWS Infrastructure

Here's what I set up:

**EKS Cluster**: Managed Kubernetes service running the containerized app
**RDS MySQL**: Managed database (db.t3.micro) with automated backups
**VPC**: Custom network with public/private subnets for security
**Load Balancer**: AWS ALB for external access to the application
**S3 Bucket**: Stores static assets like images

I kept the original EC2 setup (t2.micro) for comparison, but the main deployment is now on EKS. The networking part was tricky at first - I had to figure out how to connect the EKS pods to the RDS instance across different VPCs.

Here's how the traffic flows:

```
    🌐 USER BROWSER
         │
         │ 1. HTTP Request
         ▼
    ┌─────────────┐
    │ AWS LOAD    │
    │ BALANCER    │
    └─────┬───────┘
          │ 2. Health Check
          ▼
    ┌─────────────┐
    │ EKS SERVICE │
    │ (Port 80)   │
    └─────┬───────┘
          │ 3. Load Balance
          ▼
    ┌─────────────┐
    │ NODE.JS POD │
    │ (Port 3000) │
    └─────┬───────┘
          │ 4. Database Query
          ▼
    ┌─────────────┐
    │ RDS MYSQL   │
    │ (Port 3306) │
    └─────────────┘
```

## Terraform Setup

I defined all the AWS infrastructure in Terraform files, which was really helpful for learning. The main components are:

**EKS Configuration** (`terraform/eks/`): Sets up the Kubernetes cluster, VPC, subnets, and worker nodes
**Database** (`rds.tf`): Creates the RDS MySQL instance with proper security groups
**Storage** (`s3.tf`): Creates S3 bucket for static assets
**EC2** (`ec2.tf`): Original single-instance setup (kept for reference)

What I really liked about using Terraform is that I can recreate the entire infrastructure from scratch, and all changes are tracked in version control without being on the AWS console.

## 🚀 CI/CD Pipeline

The project includes a complete CI/CD pipeline using GitHub Actions:

### **Automated Deployment Process:**

1. **Code Push** - Changes pushed to the app repository
2. **Docker Build** - GitHub Actions builds the Docker image
3. **Image Push** - New image pushed to Docker Hub
4. **EKS Deployment** - Kubernetes deployment automatically restarted
5. **Health Check** - Verification that deployment succeeded

### **Pipeline Features:**

- ✅ **Multi-platform builds** (linux/amd64 for EKS compatibility)
- ✅ **Docker layer caching** for faster builds
- ✅ **Rolling deployments** with zero downtime
- ✅ **Health checks** to ensure deployment success
- ✅ **Automatic rollback** on deployment failure

## 🚀 Quick Deployment Options

I've created scripts to make deployment super easy! Choose your preferred setup:

### **Option 1: Full EKS Setup (Enterprise-Grade)**
```bash
./deploy-full-eks.sh
```
- **Cost**: ~$127/month
- **Time**: 10-15 minutes
- **Features**: EKS cluster, load balancer, auto-scaling, full Kubernetes
- **Best for**: Demonstrating enterprise DevOps skills

### **Option 2: Simple Setup (Cost-Effective)**
```bash
./deploy-simple.sh
```
- **Cost**: ~$17/month
- **Time**: 3-5 minutes
- **Features**: EC2 + RDS + S3, direct deployment
- **Best for**: Learning and demos

### **Destroy Everything (Save Money)**
```bash
./destroy-all.sh        # Destroys everything
./destroy-simple.sh     # Destroys only simple setup
```

### **Manual Deployment (Advanced Users):**

#### **Infrastructure Setup:**
1. Run `terraform plan` to see what will be created
2. Run `terraform apply` to create the infrastructure
3. Deploy the app to EKS using the Kubernetes manifests

#### **Application Updates:**
1. **Make changes** in the app repository
2. **Push to GitHub** - CI/CD pipeline triggers automatically
3. **Monitor deployment** in GitHub Actions
4. **Access updated app** via any of the three methods

## Testing the Application

### **🔍 Health Checks:**

```bash
# Check if pods are running
kubectl get pods -n nodejs-app

# Check service status
kubectl get services -n nodejs-app

# View deployment status
kubectl get deployments -n nodejs-app

# Check logs
kubectl logs -n nodejs-app -l app=nodejs-app
```

### **🌐 Access Methods:**

#### **1. Local Docker (localhost:3000):**

```bash
# Start local Docker container
cd 06_project/app
docker run -d -p 3000:3000 --name terraform-eks-infra \
  -e DB_HOST=host.docker.internal \
  -e DB_USER=root \
  -e DB_PASS=your_password \
  -e DB_NAME=arav_demo \
  -e TABLE_NAME=users \
  -e PORT=3000 \
  nodejs-mysql-app
```

#### **2. EKS Port-Forward (localhost:8080):**

```bash
# Manual port-forward
kubectl port-forward -n nodejs-app service/nodejs-service 8080:80

# Auto-restart port-forward (recommended)
cd 06_project && ./auto-port-forward.sh
```

#### **3. Public URL:**

- **Direct access**: `http://af2297c2cfb804d858ad1ac92e392174-1808336492.us-east-1.elb.amazonaws.com`
- **Always up-to-date** with latest deployments
- **No setup required**

### **🧪 API Testing:**

```bash
# Test main page
curl http://localhost:8080

# Get all users
curl http://localhost:8080/users

# Add a new user
curl -X POST http://localhost:8080/users \
  -H "Content-Type: application/json" \
  -d '{"name":"John Doe","email":"john@example.com"}'

# Delete a user
curl -X DELETE http://localhost:8080/users/1
```

## What I Learned

This project evolved from a simple deployment to a comprehensive DevOps pipeline. Here are the key challenges and solutions:

### **🔧 Technical Challenges:**

1. **Architecture mismatch**: Docker image built for ARM64 but EKS nodes were x86_64

   - **Solution**: Used `docker buildx` with `--platform linux/amd64`
2. **Network connectivity**: EKS cluster in different VPC than RDS

   - **Solution**: Updated RDS security groups to allow EKS VPC traffic
3. **Port-forward reliability**: Connection lost during deployments

   - **Solution**: Created auto-restart script for seamless development
4. **Repository structure**: Managing app and infrastructure code

   - **Solution**: Implemented git submodules for clean separation

### **🚀 DevOps Concepts Mastered:**

- **Container Orchestration**: Kubernetes pods, services, deployments, namespaces
- **CI/CD Pipelines**: GitHub Actions with automated testing and deployment
- **Infrastructure as Code**: Terraform for reproducible infrastructure
- **Git Submodules**: Professional repository management
- **Multi-environment deployment**: Local, staging, and production access
- **Health checks**: Automated deployment verification
- **Rolling deployments**: Zero-downtime updates

### **💡 Key Insights:**

- **Separation of concerns** between app and infrastructure code
- **Automation** reduces deployment errors and saves time
- **Multiple access methods** improve development workflow
- **Professional practices** make projects more maintainable

## 💰 Cost Considerations

I've optimized the project for different use cases:

### **Current Status: $0/month** ✅
- All infrastructure destroyed to save money
- Use deployment scripts to bring back what you need

### **Cost Breakdown:**

#### **Simple Setup (~$17/month):**
- **EC2 t2.micro**: $8.50/month (1 vCPU, 1GB RAM)
- **RDS db.t2.micro**: $8.50/month (1 vCPU, 1GB RAM)
- **S3**: ~$0.50/month (minimal usage)

#### **Full EKS Setup (~$127/month):**
- **EKS Control Plane**: $73/month (always running)
- **1x t3.small worker node**: $15/month
- **Load Balancer**: $18/month
- **EC2 t2.micro**: $8.50/month
- **RDS db.t2.micro**: $8.50/month
- **S3**: ~$0.50/month

### **Cost Optimization Tips:**
- **Use simple setup** for learning and demos
- **Destroy when not needed** - scripts make it easy to recreate
- **EKS is expensive** - only use for enterprise demos
- **Both setups use t2.micro** - consistent and cost-effective

## 🎯 Professional Features Implemented

This project now demonstrates enterprise-level DevOps practices:

### **✅ Completed:**

- **CI/CD Pipeline** - Automated deployment with GitHub Actions
- **Git Submodules** - Professional repository structure
- **Multi-environment access** - Local, staging, and production
- **Health checks** - Automated deployment verification
- **Rolling deployments** - Zero-downtime updates
- **Container orchestration** - Kubernetes best practices
- **Infrastructure as Code** - Complete Terraform automation

### **🚀 Future Enhancements:**

- **Monitoring** - Prometheus/Grafana for observability
- **Security** - RBAC, network policies, secrets management
- **Multi-environment** - Separate dev/staging/prod clusters
- **Blue-green deployments** - Advanced deployment strategies
- **Service mesh** - Istio for microservices communication

## 🏆 Interview Ready

This project showcases:

- **Full-stack development** - Frontend, backend, and database
- **Cloud architecture** - AWS services integration
- **DevOps practices** - CI/CD, IaC, containerization
- **Professional workflow** - Git submodules, automated testing
- **Problem-solving** - Real challenges and solutions
- **Modern technologies** - Kubernetes, Docker, Terraform

Perfect for demonstrating comprehensive DevOps and cloud engineering skills! 🚀
