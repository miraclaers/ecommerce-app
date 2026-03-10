# Module 4: Container Deployment with ECS

## Overview
Deploy microservices as Docker containers on Amazon ECS (Elastic Container Service) with Fargate, using AWS Systems Manager Parameter Store for centralized configuration management.

## What We'll Build
1. **ECR Repositories** - Store Docker images for each microservice
2. **Security Groups** - Control network access between components
3. **Internal Application Load Balancer** - Route traffic within VPC
4. **Parameter Store Configuration** - Centralized configuration management
5. **IAM Roles** - Permissions for ECS tasks to access AWS services
6. **ECS Cluster & Services** - Container orchestration platform
7. **Task Definitions** - Container specifications with minimal environment variables

## Architecture
```
ECS Cluster (Fargate)
├── Service: product-service (Port 8001)
├── Service: cart-service (Port 8002)  
├── Service: user-service (Port 8003)
├── Service: order-service (Port 8004)
└── Service: notification-service

Internal Application Load Balancer
├── Target Group: product-tg → product-service
├── Target Group: cart-tg → cart-service
├── Target Group: user-tg → user-service
└── Target Group: order-tg → order-service

Parameter Store (/ecommerce/dev/)
├── aws/region
├── db/host
├── db/password (SecureString)
├── user-service-url
├── cart-service-url
├── product-service-url
└── sns/topic-arn
```

### 6. ECS Services
- One for each microservice
- Desired count: 1
- Launch type: Fargate
- Subnets: Private subnets
- Load balancer: Connect to target groups

## Console Steps

### Step 1: Create ECR Repositories

## Step 1: Setup Parameter Store Configuration

### AWS Console
1. **Systems Manager Console → Parameter Store → Create parameter**
2. **Create the following parameters:**

| Parameter Name | Type | Value | Description |
|----------------|------|-------|-------------|
| `/ecommerce/dev/aws/region` | String | `ap-south-1` | AWS region |
| `/ecommerce/dev/db/host` | String | `<RDS-endpoint>` | Database host |
| `/ecommerce/dev/db/password` | SecureString | `<your-password>` | Database password |
| `/ecommerce/dev/user-service-url` | String | `http://internal.alb.cloud11.io` | User service URL |
| `/ecommerce/dev/cart-service-url` | String | `http://internal.alb.cloud11.io` | Cart service URL |
| `/ecommerce/dev/product-service-url` | String | `http://internal.alb.cloud11.io` | Product service URL |
| `/ecommerce/dev/sns/topic-arn` | String | `<SNS-topic-arn>` | SNS topic ARN |

3. **For each parameter:**
   - Name: (as above)
   - Tier: Standard
   - Type: String (or SecureString for password)
   - Data type: text
   - Value: (as specified)
   - Create parameter

### AWS CLI
```bash
# Get RDS endpoint and SNS topic ARN
RDS_ENDPOINT=$(aws rds describe-db-instances --db-instance-identifier ecommerce-db --query 'DBInstances[0].Endpoint.Address' --output text --region ap-south-1)
SNS_TOPIC_ARN=$(aws sns list-topics --query 'Topics[?contains(TopicArn, `future-store-notification`)].TopicArn' --output text --region ap-south-1)

# Create Parameter Store parameters
aws ssm put-parameter --name "/ecommerce/dev/aws/region" --value "ap-south-1" --type "String" --region ap-south-1
aws ssm put-parameter --name "/ecommerce/dev/db/host" --value "$RDS_ENDPOINT" --type "String" --region ap-south-1
aws ssm put-parameter --name "/ecommerce/dev/db/password" --value "Coep2005" --type "SecureString" --region ap-south-1
aws ssm put-parameter --name "/ecommerce/dev/user-service-url" --value "http://internal.alb.cloud11.io" --type "String" --region ap-south-1
aws ssm put-parameter --name "/ecommerce/dev/cart-service-url" --value "http://internal.alb.cloud11.io" --type "String" --region ap-south-1
aws ssm put-parameter --name "/ecommerce/dev/product-service-url" --value "http://internal.alb.cloud11.io" --type "String" --region ap-south-1
aws ssm put-parameter --name "/ecommerce/dev/sns/topic-arn" --value "$SNS_TOPIC_ARN" --type "String" --region ap-south-1
```

## Step 2: Create ECR Repositories

### AWS Console
1. **ECR Console → Repositories → Create repository**
2. **For each service create a repository:**
   - Repository name: `product-service`, `cart-service`, `user-service`, `order-service`, `notification-service`
   - Image tag mutability: Mutable
   - Scan on push: Enable
   - Create repository

### AWS CLI
```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

for service in product-service cart-service user-service order-service notification-service; do
  aws ecr create-repository \
    --repository-name $service \
    --image-scanning-configuration scanOnPush=true \
    --region ap-south-1
done

echo "ACCOUNT_ID=$ACCOUNT_ID" >> deployment/vpc-resources.txt
```

## Step 3: Update IAM Role for Parameter Store Access

### AWS Console
1. **IAM Console → Roles → future-store-ecs-task-role**
2. **Permissions tab → Attach policies**
3. **Search and attach:** `AmazonSSMReadOnlyAccess`
4. **Attach policy**

### AWS CLI
```bash
aws iam attach-role-policy \
  --role-name future-store-ecs-task-role \
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess \
  --region ap-south-1
```

## Step 4: Build and Push Docker Images

### Build Process
```bash
# Login to ECR
aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.ap-south-1.amazonaws.com

# Build and push each service
for service in product-service cart-service user-service order-service notification-service; do
  cd services/$service
  docker build -t $service .
  docker tag $service:latest $ACCOUNT_ID.dkr.ecr.ap-south-1.amazonaws.com/$service:latest
  docker push $ACCOUNT_ID.dkr.ecr.ap-south-1.amazonaws.com/$service:latest
  cd ../..
done
```

## Step 5: Create Security Groups

### AWS Console

**Internal ALB Security Group:**
1. **VPC Console → Security Groups → Create security group**
2. **Name:** `ecommerce-internal-alb-sg`
3. **VPC:** ecommerce-vpc
4. **Inbound rules:**
   - HTTP (80) from VPC CIDR (10.0.0.0/16)
   - HTTPS (443) from VPC CIDR (10.0.0.0/16)
5. **Create security group**

**ECS Security Group:**
1. **Name:** `ecommerce-ecs-sg`
2. **VPC:** ecommerce-vpc
3. **Inbound rules:**
   - Custom TCP 8001-8004 from Internal ALB security group
4. **Create security group**

**Update RDS Security Group:**
1. **Go to existing RDS security group**
2. **Add inbound rule:**
   - PostgreSQL (5432) from ECS security group

### AWS CLI
```bash
VPC_ID=$(grep "VPC_ID=" deployment/vpc-resources.txt | cut -d'=' -f2)

# Create Internal ALB Security Group
INTERNAL_ALB_SG=$(aws ec2 create-security-group \
  --group-name ecommerce-internal-alb-sg \
  --description "Security group for internal ALB" \
  --vpc-id $VPC_ID \
  --query 'GroupId' --output text --region ap-south-1)

aws ec2 authorize-security-group-ingress \
  --group-id $INTERNAL_ALB_SG \
  --protocol tcp --port 80 --cidr 10.0.0.0/16 \
  --region ap-south-1

aws ec2 authorize-security-group-ingress \
  --group-id $INTERNAL_ALB_SG \
  --protocol tcp --port 443 --cidr 10.0.0.0/16 \
  --region ap-south-1

# Create ECS Security Group
ECS_SG=$(aws ec2 create-security-group \
  --group-name ecommerce-ecs-sg \
  --description "Security group for ECS services" \
  --vpc-id $VPC_ID \
  --query 'GroupId' --output text --region ap-south-1)

aws ec2 authorize-security-group-ingress \
  --group-id $ECS_SG \
  --protocol tcp --port 8001-8004 \
  --source-group $INTERNAL_ALB_SG \
  --region ap-south-1

echo "INTERNAL_ALB_SG=$INTERNAL_ALB_SG" >> deployment/vpc-resources.txt
echo "ECS_SG=$ECS_SG" >> deployment/vpc-resources.txt
```

## Step 6: Create Internal Application Load Balancer

### AWS Console
1. **EC2 Console → Load Balancers → Create load balancer**
2. **Load balancer type:** Application Load Balancer
3. **Name:** `ecommerce-internal-alb`
4. **Scheme:** Internal
5. **IP address type:** IPv4
6. **Network mapping:**
   - VPC: ecommerce-vpc
   - Subnets: Select both private subnets
7. **Security groups:** Select `ecommerce-internal-alb-sg`
8. **Listeners:** HTTP (80) - we'll add target groups next
9. **Create load balancer**

### AWS CLI
```bash
PRIVATE_SUBNET_1=$(grep "PRIVATE_SUBNET_1=" deployment/vpc-resources.txt | cut -d'=' -f2)
PRIVATE_SUBNET_2=$(grep "PRIVATE_SUBNET_2=" deployment/vpc-resources.txt | cut -d'=' -f2)

INTERNAL_ALB_ARN=$(aws elbv2 create-load-balancer \
  --name ecommerce-internal-alb \
  --subnets $PRIVATE_SUBNET_1 $PRIVATE_SUBNET_2 \
  --security-groups $INTERNAL_ALB_SG \
  --scheme internal \
  --type application \
  --query 'LoadBalancers[0].LoadBalancerArn' --output text --region ap-south-1)

INTERNAL_ALB_DNS=$(aws elbv2 describe-load-balancers \
  --load-balancer-arns $INTERNAL_ALB_ARN \
  --query 'LoadBalancers[0].DNSName' --output text --region ap-south-1)

echo "INTERNAL_ALB_ARN=$INTERNAL_ALB_ARN" >> deployment/vpc-resources.txt
echo "INTERNAL_ALB_DNS=$INTERNAL_ALB_DNS" >> deployment/vpc-resources.txt
```

## Step 7: Create Target Groups

### AWS Console

**Note:** Cleanup steps have been removed from individual modules. A dedicated cleanup module will be provided at the end of the tutorial.
  docker tag $service:latest $ACCOUNT_ID.dkr.ecr.ap-south-1.amazonaws.com/$service:latest
  docker push $ACCOUNT_ID.dkr.ecr.ap-south-1.amazonaws.com/$service:latest
  cd ../..
done
```

### Create Security Groups
```bash
source deployment/vpc-resources.txt

# ALB Security Group
ALB_SG_ID=$(aws ec2 create-security-group \
  --group-name ecommerce-alb-sg \
  --description "Security group for ALB" \
  --vpc-id $VPC_ID \
  --region ap-south-1 \
  --query 'GroupId' \
  --output text)

aws ec2 authorize-security-group-ingress \
  --group-id $ALB_SG_ID \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0 \
  --region ap-south-1

# ECS Security Group
ECS_SG_ID=$(aws ec2 create-security-group \
  --group-name ecommerce-ecs-sg \
  --description "Security group for ECS tasks" \
  --vpc-id $VPC_ID \
  --region ap-south-1 \
  --query 'GroupId' \
  --output text)

aws ec2 authorize-security-group-ingress \
  --group-id $ECS_SG_ID \
  --protocol tcp \
  --port 8001-8004 \
  --source-group $ALB_SG_ID \
  --region ap-south-1

# Update RDS SG to allow ECS
aws ec2 authorize-security-group-ingress \
  --group-id $RDS_SG_ID \
  --protocol tcp \
  --port 5432 \
  --source-group $ECS_SG_ID \
  --region ap-south-1

echo "ALB_SG_ID=$ALB_SG_ID" >> deployment/vpc-resources.txt
echo "ECS_SG_ID=$ECS_SG_ID" >> deployment/vpc-resources.txt
```

### Create Application Load Balancer
```bash
ALB_ARN=$(aws elbv2 create-load-balancer \
  --name ecommerce-alb \
  --subnets $PUBLIC_SUBNET_1 $PUBLIC_SUBNET_2 \
  --security-groups $ALB_SG_ID \
  --scheme internet-facing \
  --type application \
  --ip-address-type ipv4 \
  --region ap-south-1 \
  --query 'LoadBalancers[0].LoadBalancerArn' \
  --output text)

ALB_DNS=$(aws elbv2 describe-load-balancers \
  --load-balancer-arns $ALB_ARN \
  --region ap-south-1 \
  --query 'LoadBalancers[0].DNSName' \
  --output text)

echo "ALB_ARN=$ALB_ARN" >> deployment/vpc-resources.txt
echo "ALB_DNS=$ALB_DNS" >> deployment/vpc-resources.txt
echo "Load Balancer DNS: $ALB_DNS"
```

### Create Target Groups
```bash
# Product Target Group
PRODUCT_TG_ARN=$(aws elbv2 create-target-group \
  --name product-tg \
  --protocol HTTP \
  --port 8001 \
  --vpc-id $VPC_ID \
  --target-type ip \
  --health-check-path /health \
  --health-check-interval-seconds 30 \
  --region ap-south-1 \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)

# Cart Target Group
CART_TG_ARN=$(aws elbv2 create-target-group \
  --name cart-tg \
  --protocol HTTP \
  --port 8002 \
  --vpc-id $VPC_ID \
  --target-type ip \
  --health-check-path /health \
  --region ap-south-1 \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)

# User Target Group
USER_TG_ARN=$(aws elbv2 create-target-group \
  --name user-tg \
  --protocol HTTP \
  --port 8003 \
  --vpc-id $VPC_ID \
  --target-type ip \
  --health-check-path /health \
  --region ap-south-1 \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)

# Order Target Group
ORDER_TG_ARN=$(aws elbv2 create-target-group \
  --name order-tg \
  --protocol HTTP \
  --port 8004 \
  --vpc-id $VPC_ID \
  --target-type ip \
  --health-check-path /health \
  --region ap-south-1 \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)

echo "PRODUCT_TG_ARN=$PRODUCT_TG_ARN" >> deployment/vpc-resources.txt
echo "CART_TG_ARN=$CART_TG_ARN" >> deployment/vpc-resources.txt
echo "USER_TG_ARN=$USER_TG_ARN" >> deployment/vpc-resources.txt
echo "ORDER_TG_ARN=$ORDER_TG_ARN" >> deployment/vpc-resources.txt
```

### Create ALB Listener with Rules
```bash
# Create listener
LISTENER_ARN=$(aws elbv2 create-listener \
  --load-balancer-arn $ALB_ARN \
  --protocol HTTP \
  --port 80 \
  --default-actions Type=fixed-response,FixedResponseConfig="{StatusCode=404,ContentType=text/plain,MessageBody=Not Found}" \
  --region ap-south-1 \
  --query 'Listeners[0].ListenerArn' \
  --output text)

# Add rules for each service
aws elbv2 create-rule \
  --listener-arn $LISTENER_ARN \
  --priority 1 \
  --conditions Field=path-pattern,Values='/api/products*' \
  --actions Type=forward,TargetGroupArn=$PRODUCT_TG_ARN \
  --region ap-south-1

aws elbv2 create-rule \
  --listener-arn $LISTENER_ARN \
  --priority 2 \
  --conditions Field=path-pattern,Values='/api/cart*' \
  --actions Type=forward,TargetGroupArn=$CART_TG_ARN \
  --region ap-south-1

aws elbv2 create-rule \
  --listener-arn $LISTENER_ARN \
  --priority 3 \
  --conditions Field=path-pattern,Values='/api/users*' \
  --actions Type=forward,TargetGroupArn=$USER_TG_ARN \
  --region ap-south-1

aws elbv2 create-rule \
  --listener-arn $LISTENER_ARN \
  --priority 4 \
  --conditions Field=path-pattern,Values='/api/orders*' \
  --actions Type=forward,TargetGroupArn=$ORDER_TG_ARN \
  --region ap-south-1

echo "LISTENER_ARN=$LISTENER_ARN" >> deployment/vpc-resources.txt
```

### Create ECS Cluster
```bash
CLUSTER_ARN=$(aws ecs create-cluster \
  --cluster-name ecommerce-cluster \
  --region ap-south-1 \
  --query 'cluster.clusterArn' \
  --output text)

echo "CLUSTER_ARN=$CLUSTER_ARN" >> deployment/vpc-resources.txt
```

### Create Task Execution Role
```bash
# Create trust policy
cat > /tmp/ecs-trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Create role
TASK_EXEC_ROLE_ARN=$(aws iam create-role \
  --role-name ecsTaskExecutionRole \
  --assume-role-policy-document file:///tmp/ecs-trust-policy.json \
  --query 'Role.Arn' \
  --output text)

# Attach policies
aws iam attach-role-policy \
  --role-name ecsTaskExecutionRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy

aws iam attach-role-policy \
  --role-name ecsTaskExecutionRole \
  --policy-arn arn:aws:iam::aws:policy/CloudWatchLogsFullAccess

echo "TASK_EXEC_ROLE_ARN=$TASK_EXEC_ROLE_ARN" >> deployment/vpc-resources.txt
```

### Create Task Definitions

See `deployment/task-definitions/` directory for JSON files.

```bash
# Register task definitions
aws ecs register-task-definition \
  --cli-input-json file://deployment/task-definitions/product-service.json \
  --region ap-south-1

# Repeat for other services
```

### Create ECS Services

```bash
# Product Service
aws ecs create-service \
  --cluster ecommerce-cluster \
  --service-name product-service \
  --task-definition product-service-task \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$PRIVATE_SUBNET_1,$PRIVATE_SUBNET_2],securityGroups=[$ECS_SG_ID],assignPublicIp=DISABLED}" \
  --load-balancers "targetGroupArn=$PRODUCT_TG_ARN,containerName=product-service,containerPort=8001" \
  --region ap-south-1

# Repeat for other services
```

## Verification

### Check Service Status
```bash
aws ecs describe-services \
  --cluster ecommerce-cluster \
  --services product-service cart-service user-service order-service \
  --region ap-south-1 \
  --query 'services[].[serviceName,status,runningCount,desiredCount]' \
  --output table
```

### Test Endpoints
```bash
ALB_DNS=$(cat deployment/vpc-resources.txt | grep ALB_DNS | cut -d'=' -f2)

curl http://$ALB_DNS/products
curl http://$ALB_DNS/users/health
```

## Cost Considerations
- Fargate: ~$0.04/hour per task (256 CPU, 512 MB)
- 4 services × 24 hours × 30 days = ~$115/month
- ALB: ~$16/month + data transfer
- ECR: $0.10/GB/month for storage

## Next Steps
After completing this module:
- ✅ Microservices running on ECS Fargate
- ✅ ALB routing traffic to services
- ✅ Services can access RDS
- Ready for Module 5: API Gateway
