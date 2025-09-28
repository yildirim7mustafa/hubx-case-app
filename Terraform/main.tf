# Provider configuration
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "hubx"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "key_name" {
  description = "EC2 Key Pair name for SSH access"
  type        = string
  default     = "hubx-key"  # AWS'de var olan key pair adınızı yazın
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "apiuser"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
  default     = "changeMe123!"
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

# Get latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# VPC Configuration
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "hubx-${var.environment}-vpc"
    Environment = var.environment
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "hubx-${var.environment}-igw"
    Environment = var.environment
  }
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name        = "hubx-${var.environment}-public"
    Environment = var.environment
    Type        = "Public"
  }
}

# Database Subnets
resource "aws_subnet" "database" {
  count = 2

  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 20}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "hubx-${var.environment}-database-${count.index + 1}"
    Environment = var.environment
    Type        = "Database"
  }
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "hubx-${var.environment}-public-rt"
    Environment = var.environment
  }
}

resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "hubx-${var.environment}-database-rt"
    Environment = var.environment
  }
}

# Route Table Association
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "database" {
  count = 2

  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}

# Security Group for EC2
resource "aws_security_group" "ec2" {
  name_prefix = "hubx-${var.environment}-ec2-"
  vpc_id      = aws_vpc.main.id

  # SSH access
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # API port (8080)
  ingress {
    description = "API"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Valkey port (6379) - for external access if needed
  ingress {
    description = "Valkey"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "hubx-${var.environment}-ec2-sg"
    Environment = var.environment
  }
}

# Security Group for RDS
resource "aws_security_group" "rds" {
  name_prefix = "hubx-${var.environment}-database-"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL from EC2"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "hubx-${var.environment}-database-sg"
    Environment = var.environment
  }
}

# RDS Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "hubx-${var.environment}-database-subnet-group"
  subnet_ids = aws_subnet.database[*].id

  tags = {
    Name        = "hubx-${var.environment}-database-subnet-group"
    Environment = var.environment
  }
}

# RDS Parameter Group
resource "aws_db_parameter_group" "main" {
  family = "postgres17"
  name   = "hubx-${var.environment}-database-params"

  parameter {
    name  = "log_connections"
    value = "1"
  }

  tags = {
    Name        = "hubx-${var.environment}-database-params"
    Environment = var.environment
  }
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier = "hubx-${var.environment}-database"

  engine         = "postgres"
  engine_version = "17.6"
  instance_class = "db.t3.micro"

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp2"
  storage_encrypted     = true

  db_name  = "apidb"
  username = var.db_username
  password = var.db_password

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  parameter_group_name   = aws_db_parameter_group.main.name

  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  skip_final_snapshot = true
  deletion_protection = false

  tags = {
    Name        = "hubx-${var.environment}-database"
    Environment = var.environment
  }
}

# EC2 Instance
resource "aws_instance" "app" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.medium"
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.ec2.id]
  subnet_id              = aws_subnet.public.id

  user_data = base64encode(<<-EOF
#!/bin/bash

# Log everything
exec > >(tee /var/log/user-data.log) 2>&1

echo "Starting user-data script..."

# Update system
apt-get update -y
apt-get upgrade -y

# Install Docker
echo "Installing Docker..."
apt-get install -y ca-certificates curl gnupg lsb-release
mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Add ubuntu user to docker group
usermod -aG docker ubuntu

# Install Docker Compose (standalone)
curl -SL https://github.com/docker/compose/releases/download/v2.24.5/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install useful tools
apt-get install -y git htop curl wget unzip

# Create app directory
mkdir -p /home/ubuntu/app
chown ubuntu:ubuntu /home/ubuntu/app

echo "Creating Docker Compose file with RDS database..."

# Create docker-compose.yml with RDS PostgreSQL (no local db)
cat > /home/ubuntu/app/docker-compose.yml << COMPOSEEOF
version: "3.9"
services:
  valkey:
    image: valkey/valkey:latest
    container_name: hubx-valkey
    ports:
      - "6379:6379"
    volumes:
      - valkey_data:/data
    restart: unless-stopped
      
  api:
    image: yildirim7mustafa/hubx-api:latest
    container_name: hubx-api
    depends_on:
      - valkey
    environment:
      POSTGRESQL_URL: postgresql://${var.db_username}:${var.db_password}@${aws_db_instance.main.address}:${aws_db_instance.main.port}/${aws_db_instance.main.db_name}?schema=public
      VALKEY_HOST: valkey
    ports:
      - "8080:8080"
    restart: unless-stopped

volumes:
  valkey_data:
COMPOSEEOF

# Set proper permissions
chown ubuntu:ubuntu /home/ubuntu/app/docker-compose.yml

echo "Waiting for Docker to be fully ready..."
sleep 60

echo "Starting HubX application as root..."
cd /home/ubuntu/app

# Test docker access
echo "Testing Docker access..."
docker --version

# Pull images and start containers as root (simpler)
echo "Pulling latest images..."
docker-compose pull

echo "Starting containers..."
docker-compose up -d

echo "Checking container status..."
docker-compose ps

echo "Making sure containers restart on boot..."
docker update --restart unless-stopped hubx-valkey hubx-api

echo "Setup completed!"
echo "API should be running at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"

# Show final status
echo "Final container status:"
docker ps
EOF
  )

  tags = {
    Name        = "hubx-${var.environment}-app"
    Environment = var.environment
  }
}

# Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet" {
  description = "ID of public subnet"
  value       = aws_subnet.public.id
}

output "database_subnets" {
  description = "List of IDs of database subnets"
  value       = aws_subnet.database[*].id
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "rds_port" {
  description = "RDS instance port"
  value       = aws_db_instance.main.port
}

output "ec2_public_ip" {
  description = "EC2 instance public IP"
  value       = aws_instance.app.public_ip
}

output "ec2_private_ip" {
  description = "EC2 instance private IP"
  value       = aws_instance.app.private_ip
}

output "ssh_command" {
  description = "SSH command to connect to EC2"
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${aws_instance.app.public_ip}"
}

output "api_url" {
  description = "API URL"
  value       = "http://${aws_instance.app.public_ip}:8080/api/documentation"
}
