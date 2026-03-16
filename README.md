# AWS eCommerce Application - Learning Project

A production-grade microservices-based eCommerce application built for learning AWS cloud services and modern application architecture.

**Author**: Chetan Agrawal  
**Website**: [www.awswithchetan.com](https://www.awswithchetan.com)

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
  - [Local Deployment](#step-1-local-deployment-recommended)
  - [AWS Deployment](#step-2-aws-deployment)
- [Cost Estimates](#cost-estimates)
- [Project Structure](#project-structure)
- [Technology Stack](#technology-stack)

## Architecture Overview

This project demonstrates a complete cloud-native application using:

### Microservices Architecture
- **Product Service** - Product catalog management (DynamoDB)
- **Cart Service** - Shopping cart operations (DynamoDB)  
- **User Service** - User profile management (RDS PostgreSQL)
- **Order Service** - Order processing and orchestration (RDS PostgreSQL)
- **Notification Service** - Asynchronous email notifications (SNS/SQS/SES)

### AWS Services
- **Frontend**: S3 + CloudFront + Route53
- **API Layer**: API Gateway (HTTP API) + VPC Link
- **Compute**: ECS/Fargate + Application Load Balancer
- **Authentication**: Cognito User Pools
- **Databases**: DynamoDB + RDS PostgreSQL
- **Messaging**: SNS + SQS + SES
- **Networking**: VPC, Subnets, Security Groups, NAT Gateway

### Architecture Diagram

![AWS Architecture](docs/architecture-diagram.png)

## Prerequisites

Before you begin, ensure you have the following tools installed on your local workstation:

### Required Tools

- **Docker** - Container runtime for running services
- **Docker Compose** - Multi-container orchestration
- **Node.js 20+** - JavaScript runtime for frontend development
- **npm** - Node package manager (comes with Node.js)
- **Git** - Version control system
- **AWS CLI** - Command-line tool for AWS services

### Installation Options

**Option 1: Automated Installation (Recommended)**

First, clone the repository:

```bash
git clone https://github.com/awswithchetan/ecommerce-web-app.git
cd ecommerce-web-app
```

Then run the installation script that automatically detects your OS and installs all prerequisites:

```bash
./install-prerequisites.sh
```

Supports:
- macOS (uses Homebrew)
- Ubuntu/Debian (uses apt)
- Amazon Linux/RHEL/CentOS (uses yum)

**Option 2: Manual Installation**

**macOS:**
```bash
# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install tools
brew install node@20 git awscli

# Install Docker Desktop
# Download from: https://www.docker.com/products/docker-desktop
```

**Ubuntu/Debian:**
```bash
# Update packages
sudo apt-get update

# Install Docker
sudo apt-get install -y docker.io docker-compose

# Install Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install Git
sudo apt-get install -y git

# Install unzip
sudo apt-get install -y unzip

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

**Amazon Linux/RHEL/CentOS:**
```bash
# Update packages
sudo yum update -y

# Install Docker
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker

# Install Node.js 20
curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
sudo yum install -y nodejs

# Install Git
sudo yum install -y git

# Install AWS CLI
sudo yum install -y aws-cli
```

### Verify Installation

After installation, verify all tools are installed correctly:

```bash
docker --version
docker-compose --version
node --version
npm --version
git --version
aws --version
```

### Post-Installation

**Linux users:** Log out and log back in for Docker group permissions to take effect, or run:
```bash
newgrp docker
```

## Getting Started

### Step 1: Local Deployment (Recommended)

Before deploying to AWS, it's highly recommended to test the application locally. This helps verify that:
- Docker images build correctly
- Services communicate properly
- Application logic works as expected
- You understand the application flow

[Local Deployment Guide](local-deployment/README.md)

Local deployment uses:
- **LocalStack** - AWS service emulator (DynamoDB, SNS, SQS, SES)
- **PostgreSQL** - Local database
- **Nginx** - API Gateway simulator
- **React Dev Server** - Frontend

**Time required**: ~15 minutes

### Step 2: AWS Deployment

Once you've verified the application works locally, deploy it to AWS to learn cloud services hands-on.

[AWS Deployment Guide](deployment/README.md)

The deployment is organized into modules:
- Module 0: Prerequisites
- Module 1: Networking (VPC, Subnets, Security Groups)
- Module 2: Data Layer (RDS, DynamoDB)
- Module 3: Authentication (Cognito)
- Module 4: Container Deployment (ECR, ECS/Fargate, ALB)
- Module 5: API Gateway (HTTP API, VPC Link)
- Module 6: Frontend Deployment (S3, CloudFront)
- Module 7: Event-Driven Architecture (SNS, SQS)
- Module 8: DNS & SSL (Route53, ACM)
- Module 9: Cleanup

**Time required**: 3-4 hours

## Cost Estimates

- **Local Development**: $0 (runs on your machine)
- **AWS Deployment** (4-hour session): ~$10-15
- **AWS Deployment** (24 hours): ~$50-75

> **Note**: Remember to clean up AWS resources after learning to avoid ongoing charges.

## Project Structure

```
ecommerce-aws-tutorial/
├── services/                    # Backend microservices
│   ├── product-service/         # Python FastAPI
│   ├── cart-service/            # Python FastAPI
│   ├── user-service/            # Python FastAPI
│   ├── order-service/           # Python FastAPI
│   └── notification-service/    # Python FastAPI
├── frontend/
│   └── react-app/               # React application
├── local-deployment/            # Local development setup
│   ├── README.md                # Local deployment guide
│   ├── docker-compose.yml       # LocalStack + services
│   ├── nginx.conf               # API Gateway simulator
│   └── data/                    # Sample product data
├── deployment/                  # AWS deployment guides
│   ├── README.md                # Deployment overview
│   └── module*.md               # Step-by-step modules
└── install-prerequisites.sh     # Tool installation script
```

## Technology Stack

**Backend**
- Python 3.11
- FastAPI
- SQLAlchemy
- Boto3 (AWS SDK)

**Frontend**
- React 18
- AWS Amplify (Authentication)
- Axios (HTTP client)

**Infrastructure**
- Docker & Docker Compose
- LocalStack (local AWS emulation)
- Nginx (reverse proxy)

## Next Steps

1. Install prerequisites using `./install-prerequisites.sh`
2. Follow the [Local Deployment Guide](local-deployment/README.md)
3. Test the application locally
4. Proceed to [AWS Deployment](deployment/README.md)
5. Clean up resources after learning

Happy Learning!
