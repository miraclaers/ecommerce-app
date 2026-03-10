# Module 9: Cleanup

## Overview
Clean up all AWS resources created during this tutorial to avoid ongoing charges.

## Resources to Delete

### Module 8: DNS & SSL
- Route53 hosted zone
- ACM SSL certificate
- Route53 DNS records

### Module 7: Event-Driven Architecture
- SNS topic
- SQS queue
- SNS subscriptions

### Module 6: Frontend Deployment
- CloudFront distribution
- S3 bucket (frontend files)

### Module 5: API Gateway
- API Gateway HTTP API
- VPC Link
- JWT Authorizer

### Module 4: Container Deployment
- ECS services
- ECS cluster
- ECS task definitions
- ECR repositories
- Application Load Balancer
- Target groups
- IAM role (ECS task role)

### Module 3: Authentication
- Cognito User Pool
- Cognito App Client

### Module 2: Data Layer
- RDS database instance
- DB subnet group
- DynamoDB tables (products, cart)
- S3 bucket (product images)
- Parameter Store parameters

### Module 1: Networking
- NAT Gateway
- Elastic IP
- Internet Gateway
- Route tables
- Subnets
- VPC
- Security groups

## Cleanup Order

Delete resources in reverse order of creation to avoid dependency issues:

1. **Module 8 resources** (DNS & SSL)
2. **Module 7 resources** (SNS/SQS)
3. **Module 6 resources** (CloudFront, S3)
4. **Module 5 resources** (API Gateway, VPC Link)
5. **Module 4 resources** (ECS, ALB, ECR)
6. **Module 3 resources** (Cognito)
7. **Module 2 resources** (RDS, DynamoDB, S3, Parameter Store)
8. **Module 1 resources** (VPC and networking components)

**Important:** Always delete resources in the correct order to avoid dependency errors and ensure complete cleanup.
