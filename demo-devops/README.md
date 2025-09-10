# DevOps Demonstration Project - Development Environment

A secure, production-ready Kubernetes infrastructure for development environment with CI/CD pipeline, RDS database, and Grafana monitoring.

🗂️ Project Structure
```
demo-devops/
├── terraform/
│   ├── modules/
│   │   ├── eks/
│   │   ├── vpc/
│   │   ├── rds/
│   │   └── secrets-manager/
│   └── environments/
│       └── dev/
├── kubernetes/
│   ├── base/
│   ├── monitoring/
│   └── app/
├── ci-cd/
│   └── github-actions/
└── README.md
```
## 🏗️ Architecture
<img width="1167" height="317" alt="image" src="https://github.com/user-attachments/assets/38f9c514-2c98-4dd5-9c5d-e24503a8a9d8" />

### Components

- **AWS EKS Cluster**: Managed Kubernetes cluster (v1.32) in private subnets
- **AWS RDS PostgreSQL**: Managed database (v15.2) with encryption
- **AWS Secrets Manager**: Secure credential storage
- **VPC Networking**: Isolated network environment
- **Grafana Monitoring**: Visualization and dashboards (v10.0.3)
- **Prometheus**: Metrics collection (v2.47.0)
- **GitHub Actions CI/CD**: Automated deployment pipeline

### Development Environment Specifics

- Single AZ deployment for cost efficiency
- Reduced resource allocation (t3.medium nodes, db.t3.micro database)
- Development-specific configuration and policies
- Automated database credential rotation
- Grafana monitoring with pre-configured dashboards

## 🚀 Quick Start

### Prerequisites

- AWS Account with appropriate permissions
- Terraform v1.3+
- kubectl
- AWS CLI
- Docker

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/devops-demonstration-project.git
   cd devops-demonstration-project
   ```

2. **Setup AWS credentials**
   ```bash
   aws configure
   ```
3. **Deploy infrastructure**
      ```bash
   cd terraform/environments/dev
   terraform init
   terraform plan -var-file=dev.tfvars
   terraform apply -var-file=dev.tfvars
   ```

4.  **Configure kubectl**
      ```bash
      aws eks update-kubeconfig --region us-west-2 --name demo-devops-dev
    
5.  **Deploy application and monitoring**
      ```bash
      ./scripts/setup.sh
      ./scripts/monitoring-test.sh
     ```





### Access Monitoring
#### Access Grafana
```bash
kubectl port-forward svc/grafana -n monitoring 3000:3000
```

#### Access Prometheus
```bash
kubectl port-forward svc/prometheus-server -n monitoring 9090:9090
```




## 🔒 Security Features

### Development-Specific Security

- **Network Isolation**: All resources in private subnets
- **Database Encryption**: RDS encryption at rest enabled
- **Secret Management**: AWS Secrets Manager for credentials
- **Pod Security**: Non-root execution, read-only filesystems
- **Network Policies**: Zero-trust networking within cluster
- **Latest Versions**: All components use latest stable versions


## 📊 Monitoring

### Pre-configured Dashboards

- **Nginx Metrics Dashboard**: HTTP requests, active connections, and error rates
- **Kubernetes Cluster**: Node metrics, pod status, and resource usage
- **Database Metrics**: Connection pool, query performance, and storage

### Metrics Collected

- Application metrics from nginx-exporter
- Kubernetes cluster metrics
- Node resource usage
- Pod performance metrics
- Custom application metrics

## 🔧 Maintenance

### Database Operations

Initialize database:
```bash
./scripts/init-database.sh
```

Test database connection:
```bash
./scripts/test-database-connection.sh
```

### Troubleshooting

View application logs:
```bash
kubectl logs -l app=nginx-app -n app-dev
```

Check pod status:
```bash
kubectl get pods -n app-dev
```

Check monitoring status:
```bash
kubectl get pods -n monitoring
```

