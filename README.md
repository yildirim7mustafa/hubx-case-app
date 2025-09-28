# HubX Infrastructure (Terraform)

This project defines the **AWS infrastructure for the HubX application** using Terraform.  
It provisions both the application layer and the database layer automatically.

## 🚀 Components

- **VPC (10.0.0.0/16)**  
  - Public Subnet (10.0.1.0/24) → Hosts the EC2 instance  
  - 2 Database Subnets (10.0.20.0/24, 10.0.21.0/24) → Used by RDS Subnet Group  
  - Internet Gateway + Route Tables  

- **EC2 Instance**  
  - Ubuntu 22.04, t3.medium  
  - Bootstraps Docker & docker-compose via user-data  
  - Runs `hubx-api` (8080) and `valkey` (6379) containers  

- **RDS PostgreSQL**  
  - PostgreSQL 17.6  
  - Subnet Group across 2 Availability Zones  
  - Security Group allows traffic only from EC2 SG on port 5432  
  - Automated backups (7 days), parameter group with connection logging enabled  

- **Security Groups**  
  - **EC2 SG**: SSH (22), HTTP (80), API (8080), Valkey (6379) open to the internet *(for demo purposes)*  
  - **RDS SG**: Allows PostgreSQL (5432) only from EC2 SG  

## 🔑 Variables

- `aws_region` → AWS region (default: eu-west-1)  
- `project_name` → Resource name prefix (default: hubx)  
- `environment` → Environment name (dev, staging, prod)  
- `key_name` → Existing EC2 key pair name in AWS  
- `db_username` / `db_password` → RDS database credentials  

---

## 📝 Note (Before Deployment)

➡️ Please go to the [AWS EC2 Console (eu-west-1)](https://eu-west-1.console.aws.amazon.com/ec2/home?region=eu-west-1) and **create a key pair named `hubx-key`**.  
⚠️ Do not lose this key — it will be required for connecting to the EC2 instance and for CI/CD usage.  

---

## 📦 Deployment

```bash
terraform init
terraform plan
terraform apply
```

## 📤 Outputs

- `ec2_public_ip` → Public IP of the application server  
- `ssh_command` → Pre-generated SSH command to access EC2  
- `api_url` → API access URL  
- `rds_endpoint` → PostgreSQL connection endpoint  

## 🔐 CI/CD – GitHub Actions Secrets (Required)

Go to **Repository → Settings → Secrets and variables → Actions → New repository secret** and add the following entries:

- **`DOCKERHUB_USERNAME`** → Your Docker Hub **username** (not your email, not your password)
- **`DOCKERHUB_TOKEN`** → Docker Hub **Personal Access Token** (not your password). Create at Docker Hub → Account Settings → Security → “New Access Token”. Grant **Read & Write**.
- **`EC2_HOST`** → EC2 public IP (e.g., `18.202.10.20`)
- **`EC2_SSH_KEY`** → The **contents** of your private key (PEM) for `hubx-key` (multiline is OK). It should start with `-----BEGIN OPENSSH PRIVATE KEY-----` or `-----BEGIN RSA PRIVATE KEY-----` and end with the matching `END` line.
- **`EC2_USER`** → SSH username (use `ubuntu`)



