# Let's Build on AWS series - eCommerce Application
This repo is a part of my course on Udemy where I have explained the architecture in detail and demonstrated complete deployment process. 

Course Link: https://www.udemy.com/course/build-ecommerce-application-on-aws/?referralCode=361CDE8C3A9653255373

## My mission
My mission is simple — to bridge the gap between learning and real-world execution. Every course and project I build is designed with one goal - to make you truly industry-ready, not just conceptually aware. These projects replicate what real Cloud, DevOps, and Solutions Architects do every single day — designing, building, troubleshooting, and scaling production-grade systems on AWS.

Instead of teaching services in isolation, I focus on connecting the dots — bringing multiple AWS services together the way they are used in real architectures. The result is deeper understanding, stronger problem-solving skills, and the confidence to build and operate cloud-native applications in AWS.

If you're looking to move beyond tutorials and start thinking like an architect, you're in the right place.

**Author**: [Chetan Agrawal](https://in.linkedin.com/in/chetan-agrawal-30107310)

**Website**: [www.awswithchetan.com](https://www.awswithchetan.com)

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Project Structure](#project-structure)
- [Cost Estimates](#cost-estimates)
- [Getting Started](#getting-started)

## Architecture Overview

This project demonstrates a complete cloud-native microservices based application where we will have Frontend layer, Backend layer, Database layer, Access Layer and Integration layer.

Below is the architecture for this application:
<img width="800" height="450" alt="image" src="https://github.com/user-attachments/assets/f4059007-aea1-4a75-9a2f-9178a86cd373" />

### AWS Services
- **Frontend**: S3 + CloudFront + Route53
- **API Layer**: API Gateway (HTTP API) + VPC Link + ALB
- **Compute**: ECS/Fargate
- **Authentication**: Cognito User Pools
- **Databases**: DynamoDB and RDS PostgreSQL
- **Messaging**: SNS + SQS (+SES)
- **Networking**: VPC, Subnets, Security Groups, NAT Gateway
- **Logs and Management**: CloudWatch, Systems Manager
- **Security**: IAM

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

### Microservices
- **Product Service** - Product catalog management (DynamoDB)
- **Cart Service** - Shopping cart operations (DynamoDB)  
- **User Service** - User profile management (RDS PostgreSQL)
- **Order Service** - Order processing and orchestration (RDS PostgreSQL)
- **Notification Service** - Asynchronous email notifications (SNS/SQS/SES)

### AWS Deployment

We will deploy this eCommerce application to AWS by going module-by-module as follows:
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

**Time required**: 4-5 hours

## Cost Estimates

- **AWS Deployment** (4-hour session): ~$1-2 (If you have new AWS account and free credits, there will be no cost).
<img width="470" height="527" alt="cost-breakdown" src="https://github.com/user-attachments/assets/ab09b0a1-c74d-4c7a-be01-ef349e7829d9" />

Note: The EC2 and EC2-other cost that you see above is for a different project I was doing, so you can omit these cost from above estimates.

**If completed in 4 hours:** ~$1.3-1.8  

> **Note**: Remember to clean up AWS resources after learning to avoid ongoing charges.

## Getting Started

1. Proceed to [AWS Deployment](deployment/README.md)
2. Clean up resources after learning

Happy Learning!
