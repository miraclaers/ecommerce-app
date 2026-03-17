# Module 10: Cleanup

## Overview
Clean up all AWS resources created during this tutorial to avoid ongoing charges.

## Cleanup Order

Delete resources in reverse order of creation to avoid dependency issues:

### 1. DNS & SSL (Module 8)
- Route53 DNS records (A records, CNAME records)
- ACM SSL certificate
- Route53 hosted zone

### 2. Image CDN (Module 9)
- CloudFront distribution (images)
- S3 bucket (product images)

### 3. Event-Driven Architecture (Module 7)
- SNS subscriptions (email, SQS)
- SQS queue
- SNS topic

### 4. Frontend Deployment (Module 6)
- CloudFront distribution (frontend)
- S3 bucket (frontend files)

### 5. API Gateway (Module 5)
- API Gateway HTTP API
- VPC Link
- JWT Authorizer

### 6. Container Deployment (Module 4)
- ECS services
- ECS cluster
- ECS task definitions
- ECR repositories
- Application Load Balancer
- Target groups
- IAM role (ECS task role)
- Security group (ECS tasks)

### 7. Authentication (Module 3)
- Cognito User Pool
- Cognito App Client

### 8. Data Layer (Module 2)
- RDS database instance
- DB subnet group
- Security group (RDS)
- DynamoDB tables (products, cart)
- Parameter Store parameters

### 9. Networking (Module 1)
- NAT Gateway
- Elastic IP
- Internet Gateway
- Route tables (public, private ECS, private database)
- Subnets (public, private ECS, private database)
- Security groups (ALB)
- VPC

**Important:** Always delete resources in the correct order to avoid dependency errors and ensure complete cleanup.
