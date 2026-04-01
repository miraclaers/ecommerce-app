# AWS eCommerce Application - Learning Project

A production-grade microservices-based eCommerce application built for learning AWS cloud services and modern application architecture.

**Author**: Chetan Agrawal  
**Website**: [www.awswithchetan.com](https://www.awswithchetan.com)

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Getting Started](#getting-started)
- [Cost Estimates](#cost-estimates)
- [Project Structure](#project-structure)

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

<img width="800" height="450" alt="project-architecture" src="https://github.com/user-attachments/assets/75df6e4c-e7a9-481b-acf2-253448ef9c61" />

## Getting Started

> **Local Deployment**: To run this application locally with Docker + LocalStack, see the [ecommerce-local-app](https://github.com/YOUR_USERNAME/ecommerce-local-app) repo.

### AWS Deployment

Deploy the ecommerce application to AWS

[AWS Deployment Guide](deployment/README.md)

The deployment is organized into modules:
- Module 0: Prerequisites
- Module 1: Networking (VPC, Subnets, Security Groups)
- Module 2: Authentication (Cognito)
- Module 3: Frontend Infrastructure (S3, CloudFront)
- Module 4: Data Layer (RDS, DynamoDB)
- Module 5: Container Deployment (ECR, ECS/Fargate, ALB)
- Module 6: API Gateway (HTTP API, VPC Link)
- Module 7: Frontend-Backend Integration
- Module 8: Notification (SNS, SQS)
- Module 9: Custom Domain & SSL (Route53, ACM)
- Module 10: Cleanup

**Time required**: 3-4 hours

## Cost Estimates

- **Local Development**: $0 (runs on your machine)
- **AWS Deployment** (4-hour session): ~$2-4
- **AWS Deployment** (24 hours): ~$10-20

> **Note**: Remember to clean up AWS resources after learning to avoid ongoing charges.

## Project Structure

```
ecommerce-web-app/
├── services/                    # Backend microservices
│   ├── product-service/         # Python FastAPI
│   ├── cart-service/            # Python FastAPI
│   ├── user-service/            # Python FastAPI
│   └── order-service/           # Python FastAPI
├── frontend/
│   └── react-app/               # React application
├── data/                        # Product data + S3 upload scripts
├── deployment/                  # AWS deployment guides
│   ├── README.md                # Deployment overview
│   └── module*.md               # Step-by-step modules
└── install-prerequisites.sh     # Tool installation script
```

## Next Steps

1. Proceed to [AWS Deployment](deployment/README.md)
2. Clean up resources after learning

Happy Learning!
