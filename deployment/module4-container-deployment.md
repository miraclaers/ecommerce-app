# Module 4: Container Deployment with ECS

## Overview
Deploy microservices as Docker containers on Amazon ECS (Elastic Container Service) with Fargate, using an internal Application Load Balancer and Parameter Store for configuration management.

## What We'll Build
- **4.1** Internal Application Load Balancer with target groups and routing rules
- **4.2** Parameter Store configuration for service URLs
- **4.3** ECR repositories for Docker images
- **4.4** Build and push Docker images to ECR
- **4.5** IAM role for ECS tasks with required permissions
- **4.6** ECS security group for container networking
- **4.7** ECS task definitions with environment variables
- **4.8** ECS cluster and services deployment
- **4.9** Service status verification
- **4.10** API endpoint testing with bastion host
- **4.11** Troubleshooting guide and common issues

---

## 4.1 Create Internal Application Load Balancer

### Create ALB Security Group

1. **VPC Console → Security Groups → Create security group**
2. **Name:** `ecommerce-alb-sg`
3. **Description:** "Security group for internal ALB"
4. **VPC:** Select `ecommerce-vpc`
5. **Inbound rules:**
   - Type: HTTP, Port: 80, Source: 10.10.0.0/16 (VPC CIDR)
   - Description: "Allow HTTP from VPC"
6. **Create security group**

### Create Internal Application Load Balancer

1. **EC2 Console → Load Balancers → Create load balancer**
2. **Application Load Balancer → Create**
3. **Basic configuration:**
   - Name: `ecommerce-internal-alb`
   - Scheme: **Internal**
   - IP address type: IPv4
4. **Network mapping:**
   - VPC: `ecommerce-vpc`
   - Subnets: Select both **private ECS subnets**
5. **Security groups:** Select `ecommerce-alb-sg`
6. **Listeners:** HTTP:80 (we'll configure target groups next)
7. **Create load balancer**

### Create Target Groups

Create 4 target groups for the microservices:

**Product Service Target Group:**
1. **EC2 Console → Target Groups → Create target group**
2. **Target type:** IP addresses
3. **Target group name:** `ecommerce-product-tg`
4. **Protocol:** HTTP, Port: 8001
5. **VPC:** `ecommerce-vpc`
6. **Health check path:** `/health`
7. **Create target group**

**Repeat for other services:**
- **Cart Service:** `ecommerce-cart-tg`, Port: 8002
- **User Service:** `ecommerce-user-tg`, Port: 8003  
- **Order Service:** `ecommerce-order-tg`, Port: 8004

### Configure ALB Listener Rules

1. **Go to Load Balancer → Listeners → HTTP:80 → View/edit rules**
2. **Add rules for path-based routing:**

**Product Service Rule:**
- **IF:** Path is `/products*`
- **THEN:** Forward to `ecommerce-product-tg`

**Cart Service Rule:**
- **IF:** Path is `/cart*`
- **THEN:** Forward to `ecommerce-cart-tg`

**User Service Rule:**
- **IF:** Path is `/users*`
- **THEN:** Forward to `ecommerce-user-tg`

**Order Service Rule:**
- **IF:** Path is `/orders*`
- **THEN:** Forward to `ecommerce-order-tg`

3. **Save rules**

---

## 4.2 Create Parameter Store Parameters

### Service URL Parameters

1. **Systems Manager Console → Parameter Store → Create parameter**

**User Service URL:**
- **Name:** `/ecommerce/dev/user-service-url`
- **Type:** String
- **Value:** `http://<internal-alb-dns-name>` (get from ALB details)

**Repeat for other services:**
- `/ecommerce/dev/cart-service-url` → `http://<internal-alb-dns-name>`
- `/ecommerce/dev/product-service-url` → `http://<internal-alb-dns-name>`

**Note:** All services use the same ALB DNS name. The ALB routes requests based on path.

---

## 4.3 Create ECR Repositories

### Create Repository for Product Service

1. **ECR Console → Repositories → Create repository**
2. **Repository name:** `ecommerce/product-service`
3. **Image scan settings:** Scan on push (optional)
4. **Encryption:** AES-256
5. **Create repository**

### Validation Table

Create repositories for all services:

| Service | Repository Name | Status |
|---------|----------------|---------|
| Product Service | `ecommerce/product-service` | ✅ Created |
| Cart Service | `ecommerce/cart-service` | ⏳ Create |
| User Service | `ecommerce/user-service` | ⏳ Create |
| Order Service | `ecommerce/order-service` | ⏳ Create |

**Repeat the above steps for the remaining 3 services.**

---

## 4.4 Build and Push Docker Images

### Build and Push Product Service Image

1. **Get ECR login command:**
```bash
aws ecr get-login-password --region <your-region> | docker login --username AWS --password-stdin <account-id>.dkr.ecr.<your-region>.amazonaws.com
```

2. **Build the image:**
```bash
cd services/product-service
docker build -t ecommerce/product-service .
```

3. **Tag the image:**
```bash
docker tag ecommerce/product-service:latest <account-id>.dkr.ecr.<your-region>.amazonaws.com/ecommerce/product-service:latest
```

4. **Push the image:**
```bash
docker push <account-id>.dkr.ecr.<your-region>.amazonaws.com/ecommerce/product-service:latest
```

**Repeat the above steps for cart-service, user-service, and order-service.**

---

## 4.5 Create IAM Role for ECS Tasks

### Create ECS Task Role

1. **IAM Console → Roles → Create role**
2. **Trusted entity type:** AWS service
3. **Service:** Elastic Container Service
4. **Use case:** Elastic Container Service Task
5. **Next**

**Attach permissions policies:**
6. **Add the following AWS managed policies:**
   - `AmazonDynamoDBFullAccess`
   - `AmazonSSMReadOnlyAccess`
   - `CloudWatchLogsFullAccess`
   - `AmazonS3ReadOnlyAccess`
   - `AmazonSNSFullAccess`

7. **Role name:** `ecommerce-ecs-task-role`
8. **Create role**

---

## 4.6 Create ECS Security Group

### ECS Tasks Security Group

1. **VPC Console → Security Groups → Create security group**
2. **Name:** `ecommerce-ecs-sg`
3. **Description:** "Security group for ECS tasks"
4. **VPC:** Select `ecommerce-vpc`
5. **Inbound rules:**
   - Type: Custom TCP, Port: 8001, Source: `ecommerce-alb-sg`
   - Type: Custom TCP, Port: 8002, Source: `ecommerce-alb-sg`
   - Type: Custom TCP, Port: 8003, Source: `ecommerce-alb-sg`
   - Type: Custom TCP, Port: 8004, Source: `ecommerce-alb-sg`
6. **Outbound rules:** All traffic (default)
7. **Create security group**

---

## 4.6 Create ECS Security Group

### ECS Tasks Security Group

1. **VPC Console → Security Groups → Create security group**
2. **Name:** `ecommerce-ecs-sg`
3. **Description:** "Security group for ECS tasks"
4. **VPC:** Select `ecommerce-vpc`
5. **Inbound rules:**
   - Type: Custom TCP, Port: 8001, Source: `ecommerce-alb-sg`
   - Type: Custom TCP, Port: 8002, Source: `ecommerce-alb-sg`
   - Type: Custom TCP, Port: 8003, Source: `ecommerce-alb-sg`
   - Type: Custom TCP, Port: 8004, Source: `ecommerce-alb-sg`
6. **Outbound rules:** All traffic (default)
7. **Create security group**

---

## 4.7 Create ECS Task Definitions

### Create Task Definition for Product Service

1. **ECS Console → Task definitions → Create new task definition**
2. **Task definition family:** `ecommerce-product-service`
3. **Launch type:** AWS Fargate
4. **Operating system:** Linux/X86_64
5. **CPU:** 0.25 vCPU
6. **Memory:** 0.5 GB
7. **Task role:** `ecommerce-ecs-task-role`
8. **Task execution role:** `ecsTaskExecutionRole`

**Container definition:**
9. **Container name:** `product-service`
10. **Image URI:** `<account-id>.dkr.ecr.<your-region>.amazonaws.com/ecommerce/product-service:latest`
11. **Port mappings:** Container port 8001, Protocol TCP
12. **Environment variables:**
    - `ENVIRONMENT` = `dev`
    - `AWS_REGION` = `<your-region>`
13. **Log configuration:**
    - Log driver: awslogs
    - Log group: `/ecommerce/product-service`
    - Region: `<your-region>`
    - Stream prefix: ecs

14. **Create task definition**

### Task Definition Validation Table

Create task definitions for all services:

| Service | Task Definition | CPU | Memory | Port | Status |
|---------|----------------|-----|--------|------|---------|
| Product Service | `ecommerce-product-service` | 0.25 vCPU | 0.5 GB | 8001 | ✅ Created |
| Cart Service | `ecommerce-cart-service` | 0.25 vCPU | 0.5 GB | 8002 | ⏳ Create |
| User Service | `ecommerce-user-service` | 0.25 vCPU | 0.5 GB | 8003 | ⏳ Create |
| Order Service | `ecommerce-order-service` | 0.25 vCPU | 0.5 GB | 8004 | ⏳ Create |

**Repeat the above steps for the remaining 3 services, changing the port numbers and image URIs accordingly.**

---

## 4.8 Create ECS Cluster and Services

### Create ECS Cluster

1. **ECS Console → Clusters → Create cluster**
2. **Cluster name:** `ecommerce-cluster`
3. **Infrastructure:** AWS Fargate (serverless)
4. **Create cluster**

### Create ECS Service for Product Service

1. **Go to cluster → Services → Create service**
2. **Launch type:** Fargate
3. **Task definition:** `ecommerce-product-service:1`
4. **Service name:** `ecommerce-product-service`
5. **Desired tasks:** 1
6. **Deployment configuration:** Rolling update
7. **VPC:** `ecommerce-vpc`
8. **Subnets:** Select both **private ECS subnets**
9. **Security group:** `ecommerce-ecs-sg`
10. **Public IP:** Disabled
11. **Load balancer type:** Application Load Balancer
12. **Load balancer:** `ecommerce-internal-alb`
13. **Target group:** `ecommerce-product-tg`
14. **Create service**

### Service Creation Validation Table

Create services for all microservices:

| Service | ECS Service Name | Target Group | Desired Tasks | Status |
|---------|-----------------|--------------|---------------|---------|
| Product Service | `ecommerce-product-service` | `ecommerce-product-tg` | 1 | ✅ Created |
| Cart Service | `ecommerce-cart-service` | `ecommerce-cart-tg` | 1 | ⏳ Create |
| User Service | `ecommerce-user-service` | `ecommerce-user-tg` | 1 | ⏳ Create |
| Order Service | `ecommerce-order-service` | `ecommerce-order-tg` | 1 | ⏳ Create |

**Repeat the above steps for the remaining 3 services.**

---

## 4.9 Verify ECS Services

### Check Service Status

1. **ECS Console → Clusters → ecommerce-cluster → Services**
2. **Verify all 4 services show:**
   - **Status:** Active
   - **Running tasks:** 1
   - **Desired tasks:** 1

### Check Target Group Health

1. **EC2 Console → Target Groups**
2. **For each target group, verify:**
   - **Registered targets:** 1
   - **Health status:** Healthy

### Check Target Group Health

1. **EC2 Console → Target Groups**
2. **For each target group, verify:**
   - **Registered targets:** 1
   - **Health status:** Healthy

---

## 4.10 Test API Endpoints

### Option 1: Launch Bastion Host (Recommended)

**Create Bastion Host:**
1. **EC2 Console → Launch Instance**
2. **Name:** `ecommerce-bastion`
3. **AMI:** Amazon Linux 2023
4. **Instance type:** t2.micro
5. **Key pair:** Select or create a key pair
6. **Network settings:**
   - VPC: `ecommerce-vpc`
   - Subnet: Select a **public subnet**
   - Auto-assign public IP: Enable
7. **Security group:** Create new
   - Name: `ecommerce-bastion-sg`
   - SSH (22) from your IP address
8. **Launch instance**

**Test API Endpoints:**
1. **SSH into bastion host:**
```bash
ssh -i your-key.pem ec2-user@<bastion-public-ip>
```

2. **Test product service:**
```bash
curl http://<internal-alb-dns-name>/products
```

3. **Test other services:**
```bash
curl http://<internal-alb-dns-name>/cart
curl http://<internal-alb-dns-name>/users
curl http://<internal-alb-dns-name>/orders
```

### Option 2: Use VPC Endpoints (Alternative)

If you prefer not to create a bastion host, you can test from AWS CloudShell or configure VPC endpoints for testing.

---

## 4.11 Troubleshooting Guide

### Check CloudWatch Logs

If services are not starting properly, check the logs:

1. **CloudWatch Console → Log groups**
2. **Check these log groups:**
   - `/ecommerce/product-service`
   - `/ecommerce/cart-service`
   - `/ecommerce/user-service`
   - `/ecommerce/order-service`

### Common Issues

**Service not starting:**
- Check ECR image URI in task definition
- Verify environment variables are set correctly
- Check IAM task execution role permissions

**Health check failing:**
- Verify `/health` endpoint exists in your service
- Check security group allows traffic on service ports
- Verify container is listening on correct port

**Parameter Store access issues:**
- Ensure task execution role has `ssm:GetParameter` permissions
- Verify parameter names match exactly (case-sensitive)
- Check parameter exists in correct region

### Useful Commands

**Check service status:**
```bash
aws ecs describe-services --cluster ecommerce-cluster --services ecommerce-product-service
```

**View recent logs:**
```bash
aws logs tail /ecommerce/product-service --follow
```

## Next Steps
Proceed to **[Module 5: API Gateway](./module5-api-gateway.md)** to create the API Gateway with VPC Link integration.
