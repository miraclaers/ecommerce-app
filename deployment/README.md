# AWS Deployment Guide - Ecommerce Application

## Overview
This guide walks you through deploying a production-ready microservices ecommerce application on AWS using modern cloud architecture patterns.

## Architecture Overview
<img width="800" height="450" alt="project-architecture" src="https://github.com/user-attachments/assets/0ec2816c-c273-46e7-b078-eda66991e0ef" />

## Deployment Modules

Complete the following deployment modules in order:

### [Module 0: Prerequisites](./module00-prerequisites.md)
**Time:** 10-15 minutes  
**Setup:** AWS CLI, Docker, Git
- Clone this repository
- Install required tools
- Configure AWS credentials

### [Module 1: Networking Foundation](./module01-networking.md)
**Time:** 15-20 minutes  
**Services:** VPC, Subnets, Internet Gateway, NAT Gateway, Route Tables
- Create VPC with public and private subnets across 2 AZs
- Set up Internet Gateway and NAT Gateway for connectivity

### [Module 2: Authentication](./module02-cognito-authentication.md)
**Time:** 5-10 minutes  
**Services:** Cognito User Pools
- User registration and authentication
- JWT token management

### [Module 3: Frontend Deployment](./module03-frontend-deployment.md)
**Time:** 20 minutes  
**Services:** S3, CloudFront
- S3 bucket for static website hosting
- CloudFront distribution for CDN and HTTPS

### [Module 4: Data Layer](./module04-data-layer.md)
**Time:** 20-30 minutes  
**Services:** DynamoDB, RDS PostgreSQL, S3
- DynamoDB tables for products and cart data
- RDS PostgreSQL for users and orders
- S3 bucket for product images

### [Module 5: Container Deployment](./module05-backend-deployment.md)
**Time:** 45-60 minutes  
**Services:** ECR, ECS, Fargate, Internal ALB, Parameter Store
- Build and push Docker images
- Deploy microservices on ECS Fargate with Parameter Store configuration
- Configure internal load balancing

### [Module 6: API Gateway](./module06-api-gateway.md)
**Time:** 30-45 minutes  
**Services:** API Gateway, VPC Link
- Create unified API endpoint with VPC Link
- Integrate Cognito authentication
- Route requests to internal ALB

### [Module 7: Frontend-Backend Integration](./module07-frontend-backend-integration.md)
**Time:** 10-15 minutes  
**Services:** S3, CloudFront
- Configure `aws-config.js` with Cognito and API Gateway values
- Build and deploy React application to S3
- Invalidate CloudFront cache

### [Module 8: Event-Driven Architecture](./module08-notification.md)
**Time:** 15 minutes  
**Services:** SNS, SQS
- Direct SNS email notifications
- SQS logging for order events

### [Module 9: DNS & SSL](./module09-custom-domain-and-ssl.md)
**Time:** 20-30 minutes (Optional)  
**Services:** Route53, Certificate Manager
- Custom domain setup
- SSL certificate configuration

### [Module 10: Cleanup](./module10-cleanup.md)
**Time:** 10-15 minutes  
- Remove all AWS resources
- Avoid ongoing charges

## Important Notes

### Region Consistency
- **Primary Region:** Choose your region for deploying all the regional services. Make sure to always check region before creating the resources.
- **Certificate Manager:** us-east-1 (required for CloudFront)

## Let's get started
Let's begin with first module **[Module 0: Pre-requisites](./module00-prerequisites.md)**.
