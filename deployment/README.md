# AWS Deployment Guide - Ecommerce Application

## Overview
This guide walks you through deploying a production-ready microservices ecommerce application on AWS using modern cloud architecture patterns.

## Architecture Overview

```
User → Route53 → CloudFront → S3 (Frontend)
                      ↓
                 API Gateway (Auth) → VPC Link → Internal ALB
                                                      ↓
                                       ┌──────────────┼──────────────┐
                                       │              │              │
                                 ECS Services    ECS Services   ECS Services
                                       │              │              │
                                       └──────────────┼──────────────┘
                                                      ↓
                                       ┌──────────────┴──────────────┐
                                       │                             │
                                     RDS                      SNS → SQS → SES
                                 PostgreSQL                  (Notifications)
                               (Users, Orders)
                                       
                                 DynamoDB (Global)
                             (Products, Cart)
```

## Security Architecture

- **Internal ALB** (not internet-facing) for enhanced security
- **VPC Link** for secure API Gateway to ALB communication
- **Parameter Store** for centralized configuration management
- **Encrypted secrets** using SecureString parameters
- **Private subnets** for all application components
- **Cognito JWT authentication** for API access

## Deployment Modules

Complete these modules in order:

### [Module 0: Prerequisites](./module0-prerequisites.md)
**Time:** 10-15 minutes  
**Setup:** AWS CLI, Docker, Git
- Install required tools
- Configure AWS credentials
- Clone repository

### [Module 1: Networking Foundation](./module1-networking.md)
**Time:** 30-45 minutes  
**Services:** VPC, Subnets, Internet Gateway, NAT Gateway, Route Tables
- Create VPC with public and private subnets across 2 AZs
- Set up Internet Gateway and NAT Gateway for connectivity

### [Module 2: Data Layer](./module2-data-layer.md)
**Time:** 45-60 minutes  
**Services:** DynamoDB, RDS PostgreSQL, S3
- DynamoDB tables for products and cart data
- RDS PostgreSQL for users and orders
- S3 bucket for product images

### [Module 3: Authentication](./module3-authentication.md)
**Time:** 30-45 minutes  
**Services:** Cognito User Pools
- User registration and authentication
- JWT token management

### [Module 4: Container Deployment](./module4-container-deployment.md)
**Time:** 60-90 minutes  
**Services:** ECR, ECS, Fargate, Internal ALB, Parameter Store
- Build and push Docker images
- Deploy microservices on ECS Fargate with Parameter Store configuration
- Configure internal load balancing

### [Module 5: API Gateway](./module5-api-gateway.md)
**Time:** 30-45 minutes  
**Services:** API Gateway, VPC Link
- Create unified API endpoint with VPC Link
- Integrate Cognito authentication
- Route requests to internal ALB

### [Module 6: Frontend Deployment](./module6-frontend-deployment.md)
**Time:** 30-45 minutes  
**Services:** S3, CloudFront
- Deploy React frontend to S3
- Configure CDN with CloudFront

### [Module 7: Event-Driven Architecture](./module7-event-driven.md)
**Time:** 30-45 minutes  
**Services:** SNS, SQS
- Direct SNS email notifications
- SQS logging for order events

### [Module 8: DNS & SSL](./module8-dns-ssl.md)
**Time:** 30-45 minutes (Optional)  
**Services:** Route53, Certificate Manager
- Custom domain setup
- SSL certificate configuration

### [Module 9: Image CDN](./module9-image-cdn.md)
**Time:** 30-45 minutes  
**Services:** S3, CloudFront, Origin Access Control
- Private S3 bucket for product images
- CloudFront distribution for global image delivery
- Update DynamoDB with CDN URLs

### [Module 10: Cleanup](./module10-cleanup.md)
**Time:** 15-20 minutes  
- Remove all AWS resources
- Avoid ongoing charges

## Important Notes

### Region Consistency
- **Primary Region:** ap-south-1 (Mumbai)
- **Certificate Manager:** us-east-1 (required for CloudFront)
- Keep all other resources in ap-south-1

## Cost Estimate (24-hour deployment)

| Service | Daily Cost |
|---------|------------|
| VPC (NAT Gateway) | $1.07 |
| DynamoDB (On-Demand) | $0.03-0.17 |
| RDS (db.t3.micro) | $0.50-0.67 |
| ECS Fargate (4 services) | $3.83 |
| Internal ALB | $0.53 |
| API Gateway + VPC Link | $0.93 |
| SNS/SQS | <$0.03 |
| S3 + CloudFront (Frontend) | $0.33-0.50 |
| S3 + CloudFront (Images) | $0.05-0.10 |
| Route53 | $0.03 |
| **Total per day** | **~$7.30-7.86** |

**If completed in 4 hours:** ~$1.20-1.30  
**Monthly production cost:** ~$218-233
