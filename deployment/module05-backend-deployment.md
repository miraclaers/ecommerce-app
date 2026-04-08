# Module 5: Backend Services Deployment (ECS and ALB)

## Overview
Deploy microservices as Docker containers on Amazon ECS (Elastic Container Service) with Fargate run time and internally expose services using internal Application Load Balancer.

<img width="600" height="300" alt="image" src="https://github.com/user-attachments/assets/ce3a7981-6d9b-42f1-a2c0-9494be3f6837" />


## In this module
- Create Application Load Balancer (internal) with target groups and routing rules
- Create ECR repositories for Docker images
- Build and push Docker images to ECR
- Create ECS task definitions, ECS cluster and Services
- Validate service availability and reachability
- Troubleshooting guide and common issues

## 4.1 Create Application Load Balancer (internal)

### 4.1.1 Create ALB Security Group

1. **EC2 Console → Security Groups → Create security group**
2. **Name:** `ecommerce-alb-sg`
3. **Description:** "Security group for internal ALB"
4. **VPC:** Select `ecommerce-vpc`
5. **Inbound rules:**
   - Type: HTTP, Port: 80, Source: 10.10.0.0/16 (VPC CIDR)
   - Description: "Allow HTTP from VPC"
6. **Outbound rules:** All traffic (default)
6. **Create security group**

<details>
<summary><strong>CLI equivalent</strong></summary>

```bash
ALB_SG=$(aws ec2 create-security-group \
  --group-name ecommerce-alb-sg \
  --description "Security group for internal ALB" \
  --vpc-id $VPC_ID \
  --query 'GroupId' --output text)

aws ec2 authorize-security-group-ingress \
  --group-id $ALB_SG \
  --protocol tcp --port 80 \
  --cidr 10.10.0.0/16

echo "ALB_SG=$ALB_SG"
```

</details>

### 4.1.2 Create Target Groups

Create 4 target groups for the microservices first (required for ALB creation):

**Product Service Target Group:**
1. **EC2 Console → Load Balancing -> Target Groups → Create target group**
2. **Target type:** IP addresses
3. **Target group name:** `product-service-tg`
4. **Protocol:** HTTP, Port: 8001
5. **VPC:** `ecommerce-vpc`
6. **Health check path:** `/health`
7. **Create target group**

**Repeat for other services target groups:**
- **Cart Service:** `cart-service-tg`, Port: 8002
- **User Service:** `user-service-tg`, Port: 8003  
- **Order Service:** `order-service-tg`, Port: 8004

### Validation Table for ALB target groups

| Target Group | Port | Health |
|---------|-----------|--------|
| product-service-tg  | 8001 | /health |
| cart-service-tg | 8002 | /health |
| user-service-tg | 8003 | /health |
| order-service-tg | 8004 | /health |

<details>
<summary><strong>CLI equivalent</strong></summary>

```bash
for SVC in "product-service-tg:8001" "cart-service-tg:8002" "user-service-tg:8003" "order-service-tg:8004"; do
  NAME=${SVC%%:*}
  PORT=${SVC##*:}
  aws elbv2 create-target-group \
    --name $NAME \
    --protocol HTTP \
    --port $PORT \
    --vpc-id $VPC_ID \
    --target-type ip \
    --health-check-path /health
done

# Capture individual ARNs for later use
PRODUCT_TG=$(aws elbv2 describe-target-groups --names product-service-tg --query 'TargetGroups[0].TargetGroupArn' --output text)
CART_TG=$(aws elbv2 describe-target-groups --names cart-service-tg --query 'TargetGroups[0].TargetGroupArn' --output text)
USER_TG=$(aws elbv2 describe-target-groups --names user-service-tg --query 'TargetGroups[0].TargetGroupArn' --output text)
ORDER_TG=$(aws elbv2 describe-target-groups --names order-service-tg --query 'TargetGroups[0].TargetGroupArn' --output text)
```

</details>

### 4.1.3 Create Application Load Balancer

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
6. **Listeners:** HTTP:80
   - **Default action:** Forward to `ecommerce-product-tg` (we'll add more rules next)
7. **Create load balancer**

<details>
<summary><strong>CLI equivalent</strong></summary>

```bash
ALB_ARN=$(aws elbv2 create-load-balancer \
  --name ecommerce-internal-alb \
  --scheme internal \
  --type application \
  --subnets $ECS_SUBNET_1 $ECS_SUBNET_2 \
  --security-groups $ALB_SG \
  --query 'LoadBalancers[0].LoadBalancerArn' --output text)

ALB_DNS=$(aws elbv2 describe-load-balancers \
  --load-balancer-arns $ALB_ARN \
  --query 'LoadBalancers[0].DNSName' --output text)

# Create listener with default action → product service
LISTENER_ARN=$(aws elbv2 create-listener \
  --load-balancer-arn $ALB_ARN \
  --protocol HTTP --port 80 \
  --default-actions Type=forward,TargetGroupArn=$PRODUCT_TG \
  --query 'Listeners[0].ListenerArn' --output text)

echo "ALB_ARN=$ALB_ARN"
echo "ALB_DNS=$ALB_DNS"
echo "LISTENER_ARN=$LISTENER_ARN"
```

</details>

### 4.1.4 Configure ALB Listener Rules

1. **Go to Load Balancer → Listeners → HTTP:80 → View/edit rules**
2. **Add rules for path-based routing:**

**Product Service Rule:**
- **IF:** Path is `/products*`
- **THEN:** Forward to `product-service-tg`

**Cart Service Rule:**
- **IF:** Path is `/cart*`
- **THEN:** Forward to `cart-service-tg`

**User Service Rule:**
- **IF:** Path is `/users*`
- **THEN:** Forward to `user-service-tg`

**Order Service Rule:**
- **IF:** Path is `/orders*`
- **THEN:** Forward to `order-service-tg`

3. **Save rules**

### Validation Table for ALB lister rules

| Rule No. | Path | Forward to |
|---------|----------|---------|
| 1  | /products* | product-service-tg |
| 2  | /cart* | cart-service-tg |
| 3  | /users* | user-service-tg |
| 4  | /orders* | order-service-tg |
| default  |  N/A | product-service-tg |

<details>
<summary><strong>CLI equivalent</strong></summary>

```bash
# Add path-based routing rules (priority 1-4)
echo "Creating ALB listener rules..."

aws elbv2 create-rule \
  --listener-arn $LISTENER_ARN --priority 1 \
  --conditions '[{"Field":"path-pattern","Values":["/products*"]}]' \
  --actions "[{\"Type\":\"forward\",\"TargetGroupArn\":\"$PRODUCT_TG\"}]" \
  --no-cli-pager > /dev/null && echo "Rule 1 created: /products* → product-service"

aws elbv2 create-rule \
  --listener-arn $LISTENER_ARN --priority 2 \
  --conditions '[{"Field":"path-pattern","Values":["/cart*"]}]' \
  --actions "[{\"Type\":\"forward\",\"TargetGroupArn\":\"$CART_TG\"}]" \
  --no-cli-pager > /dev/null && echo "Rule 2 created: /cart* → cart-service"

aws elbv2 create-rule \
  --listener-arn $LISTENER_ARN --priority 3 \
  --conditions '[{"Field":"path-pattern","Values":["/users*"]}]' \
  --actions "[{\"Type\":\"forward\",\"TargetGroupArn\":\"$USER_TG\"}]" \
  --no-cli-pager > /dev/null && echo "Rule 3 created: /users* → user-service"

aws elbv2 create-rule \
  --listener-arn $LISTENER_ARN --priority 4 \
  --conditions '[{"Field":"path-pattern","Values":["/orders*"]}]' \
  --actions "[{\"Type\":\"forward\",\"TargetGroupArn\":\"$ORDER_TG\"}]" \
  --no-cli-pager > /dev/null && echo "Rule 4 created: /orders* → order-service"

echo "All listener rules created successfully!"
```

</details>


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

<details>
<summary><strong>CLI equivalent</strong></summary>

```bash
for PARAM in user-service-url cart-service-url product-service-url; do
  aws ssm put-parameter \
    --name /ecommerce/dev/$PARAM \
    --type String \
    --value "http://$ALB_DNS"
done
```

</details>

---

## 4.3 Create ECR Repositories

### Create Repository for Product Service

1. **ECR Console → Repositories → Create repository**
2. **Repository name:** `ecommerce/product-service`
3. **Create repository**
4. **Repeat the above steps for the remaining 3 services.**

### Validation Table

Create repositories for all services:

| Service | Repository Name |
|---------|----------------|
| Product Service | `ecommerce/product-service` |
| Cart Service | `ecommerce/cart-service` |
| User Service | `ecommerce/user-service` |
| Order Service | `ecommerce/order-service` |

<details>
<summary><strong>CLI equivalent</strong></summary>

```bash
for SVC in product-service cart-service user-service order-service; do
  aws ecr create-repository --repository-name ecommerce/$SVC
done
```

</details>


## 4.4 Build and Push Docker Images

**Note:** Execute all commands in this section from your **local machine** (not from AWS console or EC2 instance).

### ECR Registry URL Format

The ECR registry URL format is: `<account-id>.dkr.ecr.<your-region>.amazonaws.com`

- **`<account-id>`** = Your 12-digit AWS Account ID
- **`<your-region>`** = Your AWS region (e.g., us-east-1, ap-south-1)

**To find your ECR registry URL:**
- **Console:** ECR Console → Repositories → Click any repository → Copy the URI (everything before the repository name)

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

### Build and Push other services

**Important:** Make sure to change to each service directory before building.

**Cart Service:**
```bash
cd ../cart-service  # Navigate to cart-service directory
docker build -t ecommerce/cart-service .
docker tag ecommerce/cart-service:latest <account-id>.dkr.ecr.<your-region>.amazonaws.com/ecommerce/cart-service:latest
docker push <account-id>.dkr.ecr.<your-region>.amazonaws.com/ecommerce/cart-service:latest
```

**User Service:**
```bash
cd ../user-service  # Navigate to user-service directory
docker build -t ecommerce/user-service .
docker tag ecommerce/user-service:latest <account-id>.dkr.ecr.<your-region>.amazonaws.com/ecommerce/user-service:latest
docker push <account-id>.dkr.ecr.<your-region>.amazonaws.com/ecommerce/user-service:latest
```

**Order Service:**
```bash
cd ../order-service  # Navigate to order-service directory
docker build -t ecommerce/order-service .
docker tag ecommerce/order-service:latest <account-id>.dkr.ecr.<your-region>.amazonaws.com/ecommerce/order-service:latest
docker push <account-id>.dkr.ecr.<your-region>.amazonaws.com/ecommerce/order-service:latest
```

<details>
<summary><strong>CLI equivalent - Build and push all services</strong></summary>

```bash
# Run from the repo root directory (ecommerce-web-app/)

# Verify Docker is accessible without sudo
if ! docker ps > /dev/null 2>&1; then
  echo "ERROR: Cannot connect to Docker daemon. Permission denied."
  echo "Fix: Log out and log back in to your terminal, then try again."
  exit 1
fi

# Retrieve account ID and region dynamically
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=$(aws configure get region)
ECR_REGISTRY="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

echo "ECR Registry: $ECR_REGISTRY"

# Authenticate Docker to ECR
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin $ECR_REGISTRY

# Build, tag and push all services
for SVC in product-service cart-service user-service order-service; do
  echo "Building $SVC..."
  cd services/$SVC
  docker build -t ecommerce/$SVC .
  docker tag ecommerce/$SVC:latest $ECR_REGISTRY/ecommerce/$SVC:latest
  docker push $ECR_REGISTRY/ecommerce/$SVC:latest
  echo "$SVC pushed successfully!"
  cd ../..
done

echo "All images pushed to ECR!"
```

</details>

## 4.5 Create IAM Role for ECS Tasks

### Create ECS Task Role

1. **IAM Console → Roles → Create role**
2. **Trusted entity type:** AWS service
3. **Service:** Elastic Container Service
4. **Use case:** Elastic Container Service Task
5. **Next**

**Attach permissions policies:**
6. **Add the following AWS managed policies:**
   - `AmazonDynamoDBFullAccess_v2` (use v2 for better security)
   - `AmazonSSMReadOnlyAccess`
   - `CloudWatchLogsFullAccess`
   - `AmazonS3ReadOnlyAccess`
   - `AmazonSNSFullAccess`

7. **Role name:** `ecommerce-ecs-task-role`
8. **Create role**

<details>
<summary><strong>CLI equivalent</strong></summary>

```bash
# Create the role with ECS trust policy
aws iam create-role \
  --role-name ecommerce-ecs-task-role \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "ecs-tasks.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }'

# Attach required policies
for POLICY in \
  arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess \
  arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess \
  arn:aws:iam::aws:policy/CloudWatchLogsFullAccess \
  arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess \
  arn:aws:iam::aws:policy/AmazonSNSFullAccess; do
  aws iam attach-role-policy \
    --role-name ecommerce-ecs-task-role \
    --policy-arn $POLICY
done
```

</details>


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

<details>
<summary><strong>CLI equivalent</strong></summary>

```bash
# Retrieve VPC_ID and ALB_SG dynamically
VPC_ID=$(aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=ecommerce-vpc" \
  --query 'Vpcs[0].VpcId' --output text)

ALB_SG=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=ecommerce-alb-sg" "Name=vpc-id,Values=$VPC_ID" \
  --query 'SecurityGroups[0].GroupId' --output text)

echo "VPC_ID=$VPC_ID"
echo "ALB_SG=$ALB_SG"

ECS_SG=$(aws ec2 create-security-group \
  --group-name ecommerce-ecs-sg \
  --description "Security group for ECS tasks" \
  --vpc-id $VPC_ID \
  --query 'GroupId' --output text)

for PORT in 8001 8002 8003 8004; do
  aws ec2 authorize-security-group-ingress \
    --group-id $ECS_SG \
    --protocol tcp --port $PORT \
    --source-group $ALB_SG
done

echo "ECS_SG=$ECS_SG"
```

</details>


## 4.7 Create ECS Task Definitions

### Create Task Definition for Product Service

1. **ECS Console → Task definitions → Create new task definition**
2. **Task definition family:** `ecommerce-product-service`
3. **Launch type:** AWS Fargate
4. **Operating system:** Linux/X86_64
5. **CPU:** 0.25 vCPU
6. **Memory:** 0.5 GB
7. **Task role:** `ecommerce-ecs-task-role`
8. **Task execution role:** Create default role (This should create a role `ecsTaskExecutionRole` automatically. We will reuse this role for other services.)

**Container definition:**

9. **Container name:** `product-service`
10. **Image URI:** `<account-id>.dkr.ecr.<your-region>.amazonaws.com/ecommerce/product-service:latest`
11. **Port mappings:** Container port 8001, Protocol TCP
12. **Environment variables:**
    - `ENVIRONMENT` = `dev`
    - `AWS_REGION` = `<your-region>`
13. **Log configuration:**
    - Log driver: awslogs
    - Log group: `/ecs/product-service`
    - Region: `<your-region>`
    - Stream prefix: ecs

14. **Create task definition**

15. **Repeat the above steps for the remaining 3 services, changing the port numbers and image URIs accordingly.**

### Task Definition Validation Table

Create task definitions for all services:

| Service | Task Definition | CPU | Memory | Port |
|---------|----------------|-----|--------|------|
| Product Service | `ecommerce-product-service` | 0.25 vCPU | 0.5 GB | 8001 |
| Cart Service | `ecommerce-cart-service` | 0.25 vCPU | 0.5 GB | 8002 |
| User Service | `ecommerce-user-service` | 0.25 vCPU | 0.5 GB | 8003 |
| Order Service | `ecommerce-order-service` | 0.25 vCPU | 0.5 GB | 8004 |

<details>
<summary><strong>CLI equivalent</strong></summary>

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=$(aws configure get region)
TASK_ROLE_ARN=arn:aws:iam::${ACCOUNT_ID}:role/ecommerce-ecs-task-role
EXEC_ROLE_ARN=arn:aws:iam::${ACCOUNT_ID}:role/ecsTaskExecutionRole

# Create the execution role if it doesn't exist yet
aws iam create-role \
  --role-name ecsTaskExecutionRole \
  --assume-role-policy-document '{
    "Version":"2012-10-17",
    "Statement":[{"Effect":"Allow","Principal":{"Service":"ecs-tasks.amazonaws.com"},"Action":"sts:AssumeRole"}]
  }' 2>/dev/null || true

aws iam attach-role-policy \
  --role-name ecsTaskExecutionRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy 2>/dev/null || true

# Register task definitions for all 4 services
for SVC_PORT in "product-service:8001" "cart-service:8002" "user-service:8003" "order-service:8004"; do
  SVC=${SVC_PORT%%:*}
  PORT=${SVC_PORT##*:}
  LOG_GROUP=/ecs/$SVC

  # Create CloudWatch log group
  aws logs create-log-group --log-group-name $LOG_GROUP 2>/dev/null || true

  aws ecs register-task-definition \
    --family ecommerce-$SVC \
    --requires-compatibilities FARGATE \
    --network-mode awsvpc \
    --cpu 256 --memory 512 \
    --task-role-arn $TASK_ROLE_ARN \
    --execution-role-arn $EXEC_ROLE_ARN \
    --container-definitions "[{
      \"name\": \"$SVC\",
      \"image\": \"${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/ecommerce/${SVC}:latest\",
      \"portMappings\": [{\"containerPort\": $PORT, \"protocol\": \"tcp\"}],
      \"environment\": [
        {\"name\": \"ENVIRONMENT\", \"value\": \"dev\"},
        {\"name\": \"AWS_REGION\", \"value\": \"$REGION\"}
      ],
      \"logConfiguration\": {
        \"logDriver\": \"awslogs\",
        \"options\": {
          \"awslogs-group\": \"$LOG_GROUP\",
          \"awslogs-region\": \"$REGION\",
          \"awslogs-stream-prefix\": \"ecs\"
        }
      }
    }]" > /dev/null && echo "Task definition registered: ecommerce-$SVC"
done

echo "All task definitions created successfully!"
```

</details>


## 4.8 Create ECS Cluster and Services

### Create ECS Cluster

1. **ECS Console → Clusters → Create cluster**
2. **Cluster name:** `ecommerce-cluster`
3. **Infrastructure:** Fargate Only (serverless)
4. **Create cluster**

### Create ECS Service for Product Service

1. **Go to cluster → Services → Create service**
2. **Launch type:** Fargate
3. **Task definition:** `ecommerce-product-service:1`
4. **Service name:** `ecommerce-product-service`
5. **Desired tasks:** 1
6. **Networking - VPC:** `ecommerce-vpc`
8. **Subnets:** Select both **private ECS subnets** (deselect rest of the subnets if they are auto selected)
9. **Security group:** `ecommerce-ecs-sg`
10. **Public IP:** Turned off
11. **Load Balancing:** Enable "Use load balancing"
12. **Load balancer type:** Application Load Balancer
13. **Load balancer:** `ecommerce-internal-alb`
14. **Target group:** `product-service-tg`
15. **Create service**
15. **Repeat the above steps for the remaining 3 services.**

### Service Creation Validation Table

Create services for all microservices:

| Service | ECS Service Name | Target Group | Desired Tasks |
|---------|-----------------|--------------|---------------|
| Product Service | `ecommerce-product-service` | `product-service-tg` | 1 |
| Cart Service | `ecommerce-cart-service` | `cart-service-tg` | 1 |
| User Service | `ecommerce-user-service` | `user-service-tg` | 1 |
| Order Service | `ecommerce-order-service` | `order-service-tg` | 1 |

<details>
<summary><strong>CLI equivalent</strong></summary>

```bash
# Retrieve VPC and subnet IDs dynamically
VPC_ID=$(aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=ecommerce-vpc" \
  --query 'Vpcs[0].VpcId' --output text)

ECS_SUBNET_1=$(aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=ecommerce-private-ecs-1" \
  --query 'Subnets[0].SubnetId' --output text)

ECS_SUBNET_2=$(aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=ecommerce-private-ecs-2" \
  --query 'Subnets[0].SubnetId' --output text)

ECS_SG=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=ecommerce-ecs-sg" "Name=vpc-id,Values=$VPC_ID" \
  --query 'SecurityGroups[0].GroupId' --output text)

# Retrieve target group ARNs
PRODUCT_TG=$(aws elbv2 describe-target-groups \
  --names product-service-tg \
  --query 'TargetGroups[0].TargetGroupArn' --output text)

CART_TG=$(aws elbv2 describe-target-groups \
  --names cart-service-tg \
  --query 'TargetGroups[0].TargetGroupArn' --output text)

USER_TG=$(aws elbv2 describe-target-groups \
  --names user-service-tg \
  --query 'TargetGroups[0].TargetGroupArn' --output text)

ORDER_TG=$(aws elbv2 describe-target-groups \
  --names order-service-tg \
  --query 'TargetGroups[0].TargetGroupArn' --output text)

echo "ECS_SUBNET_1=$ECS_SUBNET_1"
echo "ECS_SUBNET_2=$ECS_SUBNET_2"
echo "ECS_SG=$ECS_SG"

# Create ECS cluster
aws ecs create-cluster \
  --cluster-name ecommerce-cluster \
  --capacity-providers FARGATE

# Create services for all 4 microservices
declare -A TG_MAP=(
  [product-service]=$PRODUCT_TG
  [cart-service]=$CART_TG
  [user-service]=$USER_TG
  [order-service]=$ORDER_TG
)

for SVC in product-service cart-service user-service order-service; do
  aws ecs create-service \
    --cluster ecommerce-cluster \
    --service-name ecommerce-$SVC \
    --task-definition ecommerce-$SVC \
    --desired-count 1 \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={
      subnets=[$ECS_SUBNET_1,$ECS_SUBNET_2],
      securityGroups=[$ECS_SG],
      assignPublicIp=DISABLED
    }" \
    --load-balancers "[{
      \"targetGroupArn\": \"${TG_MAP[$SVC]}\",
      \"containerName\": \"$SVC\",
      \"containerPort\": $(aws ecs describe-task-definition --task-definition ecommerce-$SVC --query 'taskDefinition.containerDefinitions[0].portMappings[0].containerPort' --output text)
    }]" > /dev/null && echo "Service created: ecommerce-$SVC"
done

echo "All ECS services created successfully!"
```

</details>


## 4.9 Verify ECS Services

### Check Service Status

1. **ECS Console → Clusters → ecommerce-cluster → Services**
2. **Verify all 4 services show:**
   - **Status:** Active
   - **Running tasks:** 1
   - **Desired tasks:** 1

### Check Target Group Health

1. **EC2 Console -> Load Balancer → Target Groups**
2. **For each target group, verify:**
   - **Registered targets:** 1
   - **Health status:** Healthy

## 4.10 Test API Endpoints (Optional but recommended)

Launch a Bastion Host for Testing as we can't directly access internal ALB URL (Stop or Terminate instance after validation)
<img width="438" height="425" alt="image" src="https://github.com/user-attachments/assets/c4f521f8-5a8f-4a02-b518-70278f165720" />


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
This should return the list of all the products.

<details>
<summary><strong>CLI equivalent - Launch Bastion Host</strong></summary>

```bash
# Retrieve VPC and public subnet
VPC_ID=$(aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=ecommerce-vpc" \
  --query 'Vpcs[0].VpcId' --output text)

PUBLIC_SUBNET=$(aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=ecommerce-public-subnet-1" \
  --query 'Subnets[0].SubnetId' --output text)

# Get latest Amazon Linux 2023 AMI (kernel-6.1, matches default console AMI)
AMI_ID=$(aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=al2023-ami-2023*kernel-6.1*x86_64" \
            "Name=state,Values=available" \
  --query 'sort_by(Images, &CreationDate)[-1].ImageId' --output text)

echo "AMI_ID=$AMI_ID"

# Reuse bastion security group if it already exists
BASTION_SG=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=ecommerce-bastion-sg" "Name=vpc-id,Values=$VPC_ID" \
  --query 'SecurityGroups[0].GroupId' --output text)

if [ "$BASTION_SG" = "None" ]; then
  BASTION_SG=$(aws ec2 create-security-group \
    --group-name ecommerce-bastion-sg \
    --description "Security group for bastion host" \
    --vpc-id $VPC_ID \
    --query 'GroupId' --output text)

  aws ec2 authorize-security-group-ingress \
    --group-id $BASTION_SG \
    --protocol tcp --port 22 --cidr 0.0.0.0/0 > /dev/null
fi

BASTION_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type t2.micro \
  --subnet-id $PUBLIC_SUBNET \
  --security-group-ids $BASTION_SG \
  --associate-public-ip-address \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=ecommerce-bastion}]' \
  --query 'Instances[0].InstanceId' --output text)

echo "Waiting for bastion host to start..."
aws ec2 wait instance-running --instance-ids $BASTION_ID

BASTION_IP=$(aws ec2 describe-instances \
  --instance-ids $BASTION_ID \
  --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)

ALB_DNS=$(aws elbv2 describe-load-balancers \
  --names ecommerce-internal-alb \
  --query 'LoadBalancers[0].DNSName' --output text)

echo "Bastion Host ready!"
echo "BASTION_IP=$BASTION_IP"
echo "ALB_DNS=$ALB_DNS"
echo ""
echo "Connect via EC2 Instance Connect in the AWS Console (EC2 → Instances → ecommerce-bastion → Connect)"
echo "Test command: curl http://$ALB_DNS/products"
```

> **Remember:** Stop or terminate the bastion host after validation.
> ```bash
> aws ec2 terminate-instances --instance-ids $BASTION_ID
> ```

</details>

**Stop or terminate the bastion host ec2 instance after validation. We don't want to keep it running un-necessarily.**


## 4.11 Troubleshooting Guide

### Check CloudWatch Logs

If services are not starting properly, check the logs:

1. **CloudWatch Console → Log groups**
2. **Check these log groups:**
   - `/ecs/product-service`
   - `/ecs/cart-service`
   - `/ecs/user-service`
   - `/ecs/order-service`

**Service not starting:**
- Check ECR image URI in task definition
- Verify environment variables are set correctly
- Check IAM task role is assigned

**Health check failing:**
- Verify `/health` endpoint exists in your service
- Check security group allows traffic on service ports

**Parameter Store access issues:**
- Verify parameter names match exactly (case-sensitive)
- Check parameter exists in correct region

## Next Steps
Proceed to **[Module 6: API Gateway](./module06-api-gateway.md)**
