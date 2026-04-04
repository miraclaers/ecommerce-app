# Module 10: Cleanup

## Overview
Clean up all AWS resources created during this project to avoid ongoing charges.

## Cleanup Order

Delete resources in reverse order of creation to avoid dependency issues:

### 1. DNS & SSL (Module 9)
- Route53 DNS records (A records, CNAME records)
- ACM SSL certificate
- Route53 Public hosted zone

### 2. Notification (Module 8)
- SNS subscriptions (email, SQS)
- SQS queue
- SNS topic

### 3. API Gateway (Module 6)
- API Gateway HTTP API
- VPC Link
- JWT Authorizer

### 4. Container Deployment (Module 5)
- ECS services
- ECS cluster
- ECS task definitions
- ECR repositories
- Application Load Balancer
- Target groups
- IAM role (ECS task role)
- Security group (ECS tasks)

### 5. Data Layer (Module 4)
- RDS database instance
- DB subnet group
- Security group (RDS)
- DynamoDB tables (products, cart)
- Parameter Store parameters

### 6. Frontend Infrastructure (Module 3)
- CloudFront distribution (frontend)
- S3 bucket (frontend)

### 7. Authentication (Module 2)
- Cognito User Pool
- Cognito App Client

### 8. Networking (Module 1)
- NAT Gateway
- Release NAT Gateway Elastic IP
- Delete VPC
- Security groups (ALB)
- VPC
