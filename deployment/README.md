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

### [Module 6: Event-Driven Architecture](./module6-event-driven.md)
**Time:** 45-60 minutes  
**Services:** SNS, SQS, SES
- Asynchronous order notifications
- Email delivery system

### [Module 7: Frontend Deployment](./module7-frontend-deployment.md)
**Time:** 30-45 minutes  
**Services:** S3, CloudFront
- Deploy React frontend to S3
- Configure CDN with CloudFront

### [Module 8: DNS & SSL](./module8-dns-ssl.md)
**Time:** 30-45 minutes (Optional)  
**Services:** Route53, Certificate Manager
- Custom domain setup
- SSL certificate configuration

## Important Notes

### Region Consistency
- **Primary Region:** ap-south-1 (Mumbai)
- **Certificate Manager:** us-east-1 (required for CloudFront)
- Keep all other resources in ap-south-1

### Security Architecture
- Internal ALB (not internet-facing) for enhanced security
- VPC Link for secure API Gateway to ALB communication
- Parameter Store for centralized configuration management
- Encrypted secrets using SecureString parameters

## Cost Estimate (Monthly)

| Service | Cost |
|---------|------|
| VPC (NAT Gateway) | $32 |
| DynamoDB (On-Demand) | $1-5 |
| RDS (db.t3.micro) | $15-20 |
| ECS Fargate (4 services) | $115 |
| Internal ALB | $16 |
| API Gateway + VPC Link | $28 |
| SNS/SQS/SES | <$1 |
| S3 + CloudFront | $10-15 |
| Route53 | $1 |
| **Total** | **~$218-233/month** |

**Development Cost:**
- **4-hour session:** ~$10-15
- **24-hour deployment:** ~$50-75

**Cost Optimization Tips:**
- Stop ECS services when not in use (dev/test)
- Use Spot instances for non-critical workloads
- Review and delete unused resources regularly
