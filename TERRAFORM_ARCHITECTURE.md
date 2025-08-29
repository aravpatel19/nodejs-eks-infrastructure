# Terraform Architecture & File Communication

## Overview

This document explains how all Terraform files communicate with each other in this multi-tier infrastructure project. The architecture demonstrates Infrastructure as Code (IaC) best practices with modular design, resource dependencies, and cross-file communication.

## Project Structure

```
terraform/
├── providers.tf              # Provider configuration
├── variables.tf              # Global variables
├── terraform.tfvars          # Variable values
├── ec2.tf                    # EC2 instance configuration
├── rds.tf                    # RDS database configuration
├── s3.tf                     # S3 bucket configuration
├── eks/                      # EKS cluster module
│   ├── main.tf              # EKS cluster and IAM roles
│   ├── vpc.tf               # VPC and networking
│   ├── node-groups.tf       # EKS node groups
│   ├── variables.tf         # EKS module variables
│   ├── outputs.tf           # EKS module outputs
│   └── versions.tf          # EKS provider configuration
└── k8s-manifests/           # Kubernetes manifests
    ├── namespace.yaml
    ├── configmap.yaml
    ├── secret.yaml
    ├── deployment.yaml
    ├── service.yaml
    └── ingress.yaml
```

## File Communication Architecture

### 1. Provider Configuration (`providers.tf`)

**Purpose**: Defines the AWS provider configuration for the main Terraform configuration.

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.10.0"
    }
  }
}

provider "aws" {
  region                   = "us-east-1"
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "terraform-user"
}
```

**Communication**: 
- Sets up the AWS provider for all resources in the main configuration
- Used by: `ec2.tf`, `rds.tf`, `s3.tf`

### 2. Global Variables (`variables.tf`)

**Purpose**: Defines input variables used across multiple files.

```hcl
variable "ami_id" {
  type        = string
  description = "This is the AMI ID for the EC2 instance"
  default     = "ami-0360c520857e3138f"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "app_name" {
  type    = string
  default = "Nodejs-server"
}

variable "vpc_id" {
  default = "vpc-075b52eb2d5f7da61"
}
```

**Communication**:
- **Used by**: `ec2.tf` (ami_id, instance_type, app_name)
- **Referenced**: Variables can be overridden in `terraform.tfvars`

### 3. Variable Values (`terraform.tfvars`)

**Purpose**: Provides actual values for variables (currently empty, using defaults).

**Communication**:
- **Overrides**: Default values from `variables.tf`
- **Used by**: All files that reference variables

### 4. EC2 Configuration (`ec2.tf`)

**Purpose**: Creates EC2 instance with user data script for Node.js application.

**Key Dependencies**:
```hcl
# Uses variables from variables.tf
resource "aws_instance" "tf_ec2_instance" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = "terraform-ec2"
  
  # Uses security group module
  vpc_security_group_ids = [module.tf_module_ec2_sg.security_group_id]
  
  # Depends on S3 object creation
  depends_on = [aws_s3_object.tf_s3_object]
  
  # Uses RDS endpoint from rds.tf
  user_data = <<-EOF
    echo "DB_HOST=${local.rds_endpoint}" | sudo tee .env
    echo "DB_USER=${aws_db_instance.tf_rds_instance.username}" | sudo tee -a .env
    echo "DB_PASS=${aws_db_instance.tf_rds_instance.password}" | sudo tee -a .env
    echo "DB_NAME=${aws_db_instance.tf_rds_instance.db_name}" | sudo tee -a .env
  EOF
}
```

**Communication**:
- **Uses**: Variables from `variables.tf`
- **References**: RDS resources from `rds.tf`
- **Depends on**: S3 objects from `s3.tf`
- **Uses**: Security group module

### 5. RDS Configuration (`rds.tf`)

**Purpose**: Creates RDS MySQL database and security groups.

**Key Resources**:
```hcl
resource "aws_db_instance" "tf_rds_instance" {
  allocated_storage      = 10
  db_name                = "arav_demo"
  identifier             = "nodejs-rds-mysql"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  username               = "admin"
  password               = "password"
  publicly_accessible    = true
  vpc_security_group_ids = [aws_security_group.tf_rds_sg.id]
}

# Local value for RDS endpoint
locals {
  rds_endpoint = element(split(":", aws_db_instance.tf_rds_instance.endpoint), 0)
}
```

**Communication**:
- **Used by**: `ec2.tf` (for database connection in user_data)
- **Exports**: RDS endpoint via local value
- **Uses**: VPC ID from `variables.tf`

### 6. S3 Configuration (`s3.tf`)

**Purpose**: Creates S3 bucket and uploads static assets.

```hcl
resource "aws_s3_bucket" "tf_s3_bucket" {
  bucket = "nodejs-bkt-arav"
}

resource "aws_s3_object" "tf_s3_object" {
  bucket = aws_s3_bucket.tf_s3_bucket.bucket
  
  # Dynamic file upload from app directory
  for_each = fileset("../app/public/images", "**")
  key      = "images/${each.key}"
  source   = "../app/public/images/${each.key}"
}
```

**Communication**:
- **Used by**: `ec2.tf` (depends_on relationship)
- **References**: External files from `../app/public/images/`

## EKS Module Communication

### 7. EKS Module Structure

The EKS module is a self-contained module with its own provider and variable configuration.

#### EKS Provider (`eks/versions.tf`)
```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.10.0"
    }
  }
}

provider "aws" {
  region                   = var.region
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "terraform-user"
}
```

#### EKS Variables (`eks/variables.tf`)
```hcl
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "nodejs-eks-cluster"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}
```

#### EKS VPC (`eks/vpc.tf`)
```hcl
# Creates dedicated VPC for EKS
resource "aws_vpc" "eks_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

# Public and private subnets
resource "aws_subnet" "public_subnets" {
  count = 2
  vpc_id = aws_vpc.eks_vpc.id
  cidr_block = "10.0.${count.index + 1}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
}

resource "aws_subnet" "private_subnets" {
  count = 2
  vpc_id = aws_vpc.eks_vpc.id
  cidr_block = "10.0.${count.index + 10}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
}
```

#### EKS Cluster (`eks/main.tf`)
```hcl
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids = concat(aws_subnet.public_subnets[*].id, aws_subnet.private_subnets[*].id)
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
  }
}
```

#### EKS Node Groups (`eks/node-groups.tf`)
```hcl
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "main-node-group"
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  subnet_ids      = aws_subnet.private_subnets[*].id

  scaling_config {
    desired_size = 2
    max_size     = 4
    min_size     = 1
  }
}
```

#### EKS Outputs (`eks/outputs.tf`)
```hcl
output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.main.endpoint
}

output "vpc_id" {
  description = "ID of the VPC where the cluster is deployed"
  value       = aws_vpc.eks_vpc.id
}
```

## Cross-File Communication Patterns

### 1. Variable References
```hcl
# variables.tf defines
variable "ami_id" { default = "ami-0360c520857e3138f" }

# ec2.tf uses
resource "aws_instance" "tf_ec2_instance" {
  ami = var.ami_id  # References variable
}
```

### 2. Resource References
```hcl
# rds.tf creates
resource "aws_db_instance" "tf_rds_instance" { ... }

# ec2.tf references
user_data = <<-EOF
  echo "DB_HOST=${aws_db_instance.tf_rds_instance.endpoint}" | sudo tee .env
EOF
```

### 3. Local Values
```hcl
# rds.tf creates local value
locals {
  rds_endpoint = element(split(":", aws_db_instance.tf_rds_instance.endpoint), 0)
}

# ec2.tf uses local value
user_data = <<-EOF
  echo "DB_HOST=${local.rds_endpoint}" | sudo tee .env
EOF
```

### 4. Module Communication
```hcl
# EKS module internal communication
resource "aws_eks_cluster" "main" {
  vpc_config {
    subnet_ids = concat(aws_subnet.public_subnets[*].id, aws_subnet.private_subnets[*].id)
  }
}
```

### 5. Dependencies
```hcl
# ec2.tf explicitly depends on S3
resource "aws_instance" "tf_ec2_instance" {
  depends_on = [aws_s3_object.tf_s3_object]
}
```

### 6. Data Sources
```hcl
# eks/vpc.tf uses data source
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "public_subnets" {
  availability_zone = data.aws_availability_zones.available.names[count.index]
}
```

## Resource Dependencies Flow

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   S3 Bucket     │    │   RDS Instance  │    │   EKS Cluster   │
│   (s3.tf)       │    │   (rds.tf)      │    │   (eks/)        │
└─────────┬───────┘    └─────────┬───────┘    └─────────────────┘
          │                      │
          │ depends_on           │ provides
          ▼                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                    EC2 Instance                                 │
│                    (ec2.tf)                                    │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ User Data Script:                                       │   │
│  │ - Uses RDS endpoint from rds.tf                         │   │
│  │ - Waits for S3 objects from s3.tf                       │   │
│  │ - Uses variables from variables.tf                      │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## Complete File Communication Map

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              TERRAFORM ROOT                                    │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐      │
│  │ providers.tf│    │variables.tf │    │terraform.tfv│    │    ec2.tf   │      │
│  │             │    │             │    │    ars       │    │             │      │
│  │ - AWS       │    │ - ami_id    │    │ - Overrides │    │ - Instance  │      │
│  │ - Provider  │    │ - instance_ │    │ - Values    │    │ - User Data │      │
│  │ - Config    │    │   type      │    │             │    │ - Depends   │      │
│  │             │    │ - app_name  │    │             │    │   on S3     │      │
│  │             │    │ - vpc_id    │    │             │    │ - Uses RDS  │      │
│  └──────┬──────┘    └──────┬─────┘    └──────┬──────┘    └──────┬──────┘      │
│         │                  │                  │                  │             │
│         │ provides         │ provides         │ overrides        │ uses        │
│         ▼                  ▼                  ▼                  ▼             │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                    ALL MAIN RESOURCES                                   │   │
│  │  ┌─────────────┐              ┌─────────────┐                          │   │
│  │  │    rds.tf   │              │    s3.tf    │                          │   │
│  │  │             │              │             │                          │   │
│  │  │ - Database  │              │ - Bucket    │                          │   │
│  │  │ - Security  │              │ - Objects   │                          │   │
│  │  │   Groups    │              │ - Images    │                          │   │
│  │  │ - Endpoint  │              │             │                          │   │
│  │  │   Export    │              │             │                          │   │
│  │  └──────┬──────┘              └──────┬─────┘                          │   │
│  │         │                            │                                │   │
│  │         │ provides endpoint          │ provides objects               │   │
│  │         ▼                            ▼                                │   │
│  │  ┌─────────────────────────────────────────────────────────────────┐ │   │
│  │  │                    EC2 INSTANCE                                │ │   │
│  │  │  ┌─────────────────────────────────────────────────────────┐   │ │   │
│  │  │  │ User Data Script:                                       │   │ │   │
│  │  │  │ - DB_HOST=${local.rds_endpoint}                         │   │ │   │
│  │  │  │ - DB_USER=${aws_db_instance.tf_rds_instance.username}   │   │ │   │
│  │  │  │ - DB_PASS=${aws_db_instance.tf_rds_instance.password}   │   │ │   │
│  │  │  │ - DB_NAME=${aws_db_instance.tf_rds_instance.db_name}    │   │ │   │
│  │  │  │ - depends_on = [aws_s3_object.tf_s3_object]            │   │ │   │
│  │  │  └─────────────────────────────────────────────────────────┘   │ │   │
│  │  └─────────────────────────────────────────────────────────────────┘ │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              EKS MODULE                                        │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐      │
│  │eks/versions.│    │eks/variables│    │  eks/vpc.tf │    │eks/main.tf  │      │
│  │     tf      │    │     .tf     │    │             │    │             │      │
│  │             │    │             │    │             │    │             │      │
│  │ - AWS       │    │ - cluster_  │    │ - VPC       │    │ - EKS       │      │
│  │   Provider  │    │   name      │    │ - Subnets   │    │   Cluster   │      │
│  │ - EKS       │    │ - k8s_      │    │ - IGW       │    │ - IAM       │      │
│  │   Specific  │    │   version   │    │ - NAT GW    │    │   Roles     │      │
│  │             │    │ - region    │    │ - Routes    │    │ - Policies  │      │
│  └──────┬──────┘    └──────┬─────┘    └──────┬──────┘    └──────┬──────┘      │
│         │                  │                  │                  │             │
│         │ provides         │ provides         │ provides         │ uses        │
│         ▼                  ▼                  ▼                  ▼             │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                    EKS NODE GROUPS                                     │   │
│  │  ┌─────────────────────────────────────────────────────────────────┐   │   │
│  │  │                eks/node-groups.tf                               │   │   │
│  │  │  ┌─────────────────────────────────────────────────────────┐   │   │   │
│  │  │  │ - cluster_name = aws_eks_cluster.main.name              │   │   │   │
│  │  │  │ - node_role_arn = aws_iam_role.eks_node_group_role.arn  │   │   │   │
│  │  │  │ - subnet_ids = aws_subnet.private_subnets[*].id         │   │   │   │
│  │  │  │ - scaling_config { desired_size = 2, max_size = 4 }     │   │   │   │
│  │  │  └─────────────────────────────────────────────────────────┘   │   │   │
│  │  └─────────────────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                    │                                           │
│                                    │ exports                                   │
│                                    ▼                                           │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                    eks/outputs.tf                                      │   │
│  │  ┌─────────────────────────────────────────────────────────────────┐   │   │
│  │  │ - cluster_endpoint                                             │   │   │
│  │  │ - cluster_security_group_id                                    │   │   │
│  │  │ - cluster_iam_role_name                                        │   │   │
│  │  │ - cluster_certificate_authority_data                           │   │   │
│  │  │ - cluster_name                                                 │   │   │
│  │  │ - vpc_id                                                       │   │   │
│  │  │ - private_subnet_ids                                           │   │   │
│  │  │ - public_subnet_ids                                            │   │   │
│  │  └─────────────────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## Communication Summary

### Main Configuration Files
1. **`providers.tf`** → Sets up AWS provider for all main resources
2. **`variables.tf`** → Defines variables used by EC2, RDS, S3
3. **`terraform.tfvars`** → Overrides variable defaults
4. **`ec2.tf`** → Uses variables, references RDS, depends on S3
5. **`rds.tf`** → Provides database resources to EC2
6. **`s3.tf`** → Provides static assets to EC2

### EKS Module (Self-Contained)
1. **`eks/versions.tf`** → EKS-specific provider configuration
2. **`eks/variables.tf`** → EKS module variables
3. **`eks/vpc.tf`** → VPC and networking for EKS
4. **`eks/main.tf`** → EKS cluster and IAM roles
5. **`eks/node-groups.tf`** → Worker nodes
6. **`eks/outputs.tf`** → Exports cluster information

### Key Communication Patterns
- **Variable References**: `var.variable_name`
- **Resource References**: `resource_type.resource_name.attribute`
- **Local Values**: `local.value_name`
- **Module Outputs**: `module.module_name.output_name`
- **Data Sources**: `data.data_source_name.attribute`
- **Explicit Dependencies**: `depends_on = [resource]`

## Best Practices Demonstrated

### 1. **Separation of Concerns**
- Each file has a specific purpose
- EKS module is self-contained
- Clear resource organization

### 2. **Dependency Management**
- Explicit dependencies where needed
- Implicit dependencies through references
- Proper resource ordering

### 3. **Variable Management**
- Centralized variable definitions
- Default values with override capability
- Type validation and descriptions

### 4. **Modular Design**
- EKS as separate module
- Reusable components
- Clear interfaces between modules

### 5. **Resource Naming**
- Consistent naming conventions
- Descriptive resource names
- Proper tagging strategy

## Troubleshooting Communication Issues

### Common Issues
1. **Circular Dependencies**: Resources referencing each other
2. **Missing References**: Referencing non-existent resources
3. **Variable Scope**: Variables not accessible across files
4. **Module Communication**: Incorrect module output references

### Debugging Commands
```bash
# Check resource dependencies
terraform graph | dot -Tpng > graph.png

# Validate configuration
terraform validate

# Plan to see resource creation order
terraform plan

# Check variable values
terraform console
> var.ami_id
```

## Conclusion

This Terraform architecture demonstrates sophisticated Infrastructure as Code practices with:
- **Clear file separation** and responsibilities
- **Proper dependency management** between resources
- **Modular design** with self-contained EKS module
- **Cross-file communication** through variables, references, and locals
- **Best practices** for maintainable and scalable infrastructure

The communication patterns ensure that resources are created in the correct order and can access the information they need from other resources, creating a cohesive and functional infrastructure deployment.
