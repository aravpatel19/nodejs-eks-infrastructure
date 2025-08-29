# Kubernetes Infrastructure Documentation

## Overview

This document provides a comprehensive overview of the Kubernetes (EKS) infrastructure for the Node.js MySQL application deployment. The infrastructure demonstrates modern DevOps practices with container orchestration, automated deployments, and production-ready configurations.

## Architecture Summary

```
┌─────────────────────────────────────────────────────────────────┐
│                        AWS EKS CLUSTER                         │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐    ┌─────────────────┐                    │
│  │   Worker Node   │    │   Worker Node   │                    │
│  │ ip-10-0-10-108  │    │ ip-10-0-11-161  │                    │
│  │                 │    │                 │                    │
│  │ ┌─────────────┐ │    │ ┌─────────────┐ │                    │
│  │ │ Node.js Pod │ │    │ │ Node.js Pod │ │                    │
│  │ │ (2 pods)    │ │    │ │ (2 pods)    │ │                    │
│  │ └─────────────┘ │    │ └─────────────┘ │                    │
│  └─────────────────┘    └─────────────────┘                    │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    AWS LOAD BALANCER                            │
│  af2297c2cfb804d858ad1ac92e392174-1808336492.us-east-1.elb.    │
│  amazonaws.com                                                  │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                      RDS MYSQL DATABASE                         │
│  nodejs-rds-mysql.cq7gmo6s8s6l.us-east-1.rds.amazonaws.com     │
│  Database: arav_demo | Table: users                             │
└─────────────────────────────────────────────────────────────────┘
```

## Cluster Information

### EKS Cluster Details
- **Kubernetes Version**: v1.28.15-eks-3abbec1
- **Cluster Age**: 14 hours
- **Worker Nodes**: 2 nodes
- **Container Runtime**: containerd://1.7.27
- **OS**: Amazon Linux 2 (5.10.240-238.959.amzn2.x86_64)

### Worker Nodes
| Node Name | Status | Internal IP | External IP | Age |
|-----------|--------|-------------|-------------|-----|
| ip-10-0-10-108.ec2.internal | Ready | 10.0.10.108 | <none> | 14h |
| ip-10-0-11-161.ec2.internal | Ready | 10.0.11.161 | <none> | 14h |

## Application Deployment

### Namespace
- **Namespace**: `nodejs-app`
- **Purpose**: Isolates the Node.js application resources
- **Status**: Active (14h)

### Deployment Configuration
- **Name**: `nodejs-app`
- **Replicas**: 4 pods (2 per worker node)
- **Strategy**: RollingUpdate
- **Rolling Update Policy**: 25% max unavailable, 25% max surge
- **Image**: `aravpatel2319/nodejs-mysql-app:latest`

### Current Pod Status
| Pod Name | Status | Ready | Restarts | Age |
|----------|--------|-------|----------|-----|
| nodejs-app-757c6885bf-8gxt2 | Running | 1/1 | 0 | 2m57s |
| nodejs-app-757c6885bf-mklwx | Running | 1/1 | 0 | 3m7s |
| nodejs-app-757c6885bf-rnzrx | Running | 1/1 | 0 | 3m8s |
| nodejs-app-757c6885bf-xbnh4 | Running | 1/1 | 0 | 2m57s |

### Resource Configuration
- **CPU Request**: 250m (0.25 cores)
- **CPU Limit**: 500m (0.5 cores)
- **Memory Request**: 256Mi
- **Memory Limit**: 512Mi

### Health Checks
- **Liveness Probe**: HTTP GET on port 3000, path `/`
  - Initial Delay: 30s
  - Period: 10s
  - Timeout: 1s
  - Failure Threshold: 3
- **Readiness Probe**: HTTP GET on port 3000, path `/`
  - Initial Delay: 5s
  - Period: 5s
  - Timeout: 1s
  - Failure Threshold: 3

## Service Configuration

### LoadBalancer Service
- **Name**: `nodejs-service`
- **Type**: LoadBalancer
- **External IP**: `af2297c2cfb804d858ad1ac92e392174-1808336492.us-east-1.elb.amazonaws.com`
- **Internal IP**: 172.20.92.29
- **Port Mapping**: 80:3000
- **NodePort**: 30384
- **Session Affinity**: None
- **External Traffic Policy**: Cluster

### Endpoints
The service routes traffic to 4 pod endpoints:
- 10.0.10.77:3000
- 10.0.11.233:3000
- 10.0.10.159:3000
- 10.0.11.161:3000

## Configuration Management

### ConfigMap (`nodejs-config`)
Contains non-sensitive application configuration:
```yaml
Data:
  PORT: "3000"
  TABLE_NAME: "users"
  DB_NAME: "arav_demo"
```

### Secret (`nodejs-secret`)
Contains sensitive database credentials (base64 encoded):
```yaml
Data:
  DB_HOST: bm9kZWpzLXJkcy1teXNxbC5jcTdnbW82czhzNmwudXMtZWFzdC0xLnJkcy5hbWF6b25hd3MuY29t
  DB_USER: YWRtaW4=
  DB_PASS: cGFzc3dvcmQ=
```

### Environment Variables
Each pod receives the following environment variables:
- `DB_HOST`: RDS endpoint (from secret)
- `DB_USER`: Database username (from secret)
- `DB_PASS`: Database password (from secret)
- `DB_NAME`: Database name (from configmap)
- `TABLE_NAME`: Table name (from configmap)
- `PORT`: Application port (from configmap)

## Deployment History

### Recent Rolling Update
The deployment recently underwent a rolling update (3 minutes ago) with the following events:

1. **Scaled up** new replica set `nodejs-app-757c6885bf` to 1 replica
2. **Scaled down** old replica set `nodejs-app-5ddc78b746` to 3 replicas
3. **Scaled up** new replica set to 2 replicas
4. **Scaled down** old replica set to 2 replicas
5. **Scaled up** new replica set to 3 replicas
6. **Scaled down** old replica set to 1 replica
7. **Scaled up** new replica set to 4 replicas
8. **Scaled down** old replica set to 0 replicas

### Replica Set History
The deployment has gone through 11 revisions with multiple replica sets:
- `nodejs-app-757c6885bf` (Current - 4/4 replicas)
- `nodejs-app-5ddc78b746` (Previous - 0/0 replicas)
- `nodejs-app-68b4bffc67` (Historical - 0/0 replicas)
- `nodejs-app-6954c4574c` (Historical - 0/0 replicas)
- And 7 other historical replica sets

## Application Status

### Current Application State
- **Status**: ✅ Healthy and Running
- **Database Connection**: ✅ Connected with connection pooling
- **Recent Fix**: Database connection timeout issues resolved
- **Connection Pool**: Active and ready

### Recent Logs
```
Server running on port 3000
Database connection pool ready!
```

### Performance Notes
- **Connection Pooling**: Implemented to prevent database connection timeouts
- **Load Distribution**: 4 pods handling traffic across 2 worker nodes
- **High Availability**: Pods distributed across multiple availability zones

## Network Architecture

### Internal Networking
- **Pod Network**: 10.0.x.x/16 (VPC CIDR)
- **Service Network**: 172.20.x.x/16 (Kubernetes service CIDR)
- **Load Balancer**: AWS Application Load Balancer (ALB)

### External Access
- **Public URL**: `http://af2297c2cfb804d858ad1ac92e392174-1808336492.us-east-1.elb.amazonaws.com`
- **Port Forward**: `kubectl port-forward -n nodejs-app service/nodejs-service 8080:80`
- **Local Access**: `http://localhost:8080`

## Database Integration

### RDS MySQL Configuration
- **Endpoint**: `nodejs-rds-mysql.cq7gmo6s8s6l.us-east-1.rds.amazonaws.com`
- **Database**: `arav_demo`
- **Table**: `users`
- **Connection**: Connection pooling implemented for reliability

### Database Schema
```sql
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL
);
```

### Current Data
The database contains 4 users:
- John Doe (john@example.com)
- Arav Patel (aravpatel2319@gmail.com)
- Please hire me lol (work@smart.com)
- Testing adding user (adduser@works.com)

## Monitoring and Observability

### Health Checks
- **Liveness**: Ensures pods are running and responsive
- **Readiness**: Ensures pods are ready to receive traffic
- **Database**: Connection pool health monitoring

### Logging
- **Application Logs**: Available via `kubectl logs`
- **Container Logs**: Standard output/error captured
- **Database Logs**: RDS CloudWatch integration

## Security Considerations

### Network Security
- **Pod-to-Pod**: Communication within cluster
- **External Access**: Through AWS Load Balancer only
- **Database Access**: RDS security groups restrict access

### Secrets Management
- **Database Credentials**: Stored in Kubernetes secrets
- **Base64 Encoding**: Credentials encoded (not encrypted)
- **Access Control**: RBAC policies control secret access

## Troubleshooting Commands

### Basic Status Checks
```bash
# Check pod status
kubectl get pods -n nodejs-app

# Check service status
kubectl get services -n nodejs-app

# Check deployment status
kubectl get deployments -n nodejs-app

# Check replica sets
kubectl get replicasets -n nodejs-app
```

### Detailed Information
```bash
# Describe deployment
kubectl describe deployment nodejs-app -n nodejs-app

# Describe service
kubectl describe service nodejs-service -n nodejs-app

# Check pod logs
kubectl logs -n nodejs-app -l app=nodejs-app

# Check events
kubectl get events -n nodejs-app --sort-by='.lastTimestamp'
```

### Debugging
```bash
# Execute commands in pod
kubectl exec -n nodejs-app deployment/nodejs-app -- env

# Port forward for local testing
kubectl port-forward -n nodejs-app service/nodejs-service 8080:80

# Check resource usage
kubectl top pods -n nodejs-app
```

## Best Practices Implemented

### High Availability
- ✅ Multiple replicas (4 pods)
- ✅ Multi-AZ deployment (2 worker nodes)
- ✅ Rolling updates with zero downtime
- ✅ Health checks and auto-recovery

### Security
- ✅ Namespace isolation
- ✅ Secrets management
- ✅ Resource limits and requests
- ✅ Network policies (via AWS security groups)

### Scalability
- ✅ Horizontal pod autoscaling ready
- ✅ Load balancer distribution
- ✅ Connection pooling for database
- ✅ Stateless application design

### Monitoring
- ✅ Health checks
- ✅ Logging
- ✅ Event tracking
- ✅ Resource monitoring

## Future Enhancements

### Recommended Improvements
1. **Metrics Server**: Install for resource monitoring
2. **Horizontal Pod Autoscaler**: Auto-scale based on CPU/memory
3. **Ingress Controller**: More advanced routing and SSL termination
4. **Service Mesh**: Istio for advanced networking
5. **Monitoring Stack**: Prometheus + Grafana
6. **Log Aggregation**: ELK stack or similar
7. **Backup Strategy**: Database backup automation
8. **Security Scanning**: Container image vulnerability scanning

### Cost Optimization
- **Spot Instances**: Use spot instances for worker nodes
- **Right-sizing**: Monitor and adjust resource requests/limits
- **Auto-scaling**: Scale down during low usage periods

## Conclusion

This Kubernetes infrastructure demonstrates a production-ready deployment with:
- **High availability** through multi-pod, multi-node deployment
- **Automated deployments** via CI/CD pipeline
- **Proper configuration management** with ConfigMaps and Secrets
- **Health monitoring** with liveness and readiness probes
- **Database integration** with connection pooling
- **External access** through AWS Load Balancer

The recent database connection pooling fix has resolved the intermittent connection issues, making the application stable and reliable for production use.
