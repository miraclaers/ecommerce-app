# Module 1: Networking Foundation

## Overview
Create VPC infrastructure with public and private subnets across 2 availability zones for the ecommerce application.

## What We'll Build
1. **VPC** - Virtual Private Cloud with 10.10.0.0/16 CIDR
2. **Public Subnets** - 2 subnets for internet-facing resources (NAT Gateway, Bastion)
3. **Private ECS Subnets** - 2 subnets for application services
4. **Private Database Subnets** - 2 subnets for RDS instances
5. **Internet Gateway** - Internet access for public subnets
6. **NAT Gateway** - Outbound internet access for private subnets
7. **Route Tables** - Traffic routing configuration

## Architecture
```
ecommerce-vpc (10.10.0.0/16)
├── Public Subnets (Internet Gateway)
│   ├── ecommerce-public-subnet-1 (10.10.0.0/24) - ap-south-1a
│   └── ecommerce-public-subnet-2 (10.10.1.0/24) - ap-south-1b
├── Private ECS Subnets (NAT Gateway)
│   ├── ecommerce-private-ecs-1 (10.10.10.0/24) - ap-south-1a
│   └── ecommerce-private-ecs-2 (10.10.11.0/24) - ap-south-1b
└── Private Database Subnets (NAT Gateway)
    ├── ecommerce-private-database-1 (10.10.20.0/24) - ap-south-1a
    └── ecommerce-private-database-2 (10.10.21.0/24) - ap-south-1b
```

## Step 1: Create VPC

### AWS Console
1. **VPC Console → Your VPCs → Create VPC**
2. **Name:** `ecommerce-vpc`
3. **IPv4 CIDR block:** `10.10.0.0/16`
4. **IPv6 CIDR block:** No IPv6 CIDR block
5. **Tenancy:** Default
6. **Create VPC**

### AWS CLI
```bash
# Create VPC
VPC_ID=$(aws ec2 create-vpc \
  --cidr-block 10.10.0.0/16 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=ecommerce-vpc}]' \
  --query 'Vpc.VpcId' --output text --region ap-south-1)

echo "VPC_ID=$VPC_ID" > deployment/vpc-resources.txt
echo "Created VPC: $VPC_ID"
```

## Step 2: Create Internet Gateway

### AWS Console
1. **VPC Console → Internet Gateways → Create internet gateway**
2. **Name:** `ecommerce-igw`
3. **Create internet gateway**
4. **Actions → Attach to VPC**
5. **Select:** ecommerce-vpc
6. **Attach internet gateway**

### AWS CLI
```bash
# Create Internet Gateway
IGW_ID=$(aws ec2 create-internet-gateway \
  --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=ecommerce-igw}]' \
  --query 'InternetGateway.InternetGatewayId' --output text --region ap-south-1)

# Attach to VPC
aws ec2 attach-internet-gateway \
  --internet-gateway-id $IGW_ID \
  --vpc-id $VPC_ID --region ap-south-1

echo "IGW_ID=$IGW_ID" >> deployment/vpc-resources.txt
echo "Created Internet Gateway: $IGW_ID"
```

## Step 3: Create Subnets

### AWS Console

**Public Subnet 1:**
1. **VPC Console → Subnets → Create subnet**
2. **VPC:** ecommerce-vpc
3. **Name:** `ecommerce-public-subnet-1`
4. **Availability Zone:** ap-south-1a
5. **IPv4 CIDR block:** `10.10.0.0/24`
6. **Create subnet**

**Repeat for all 6 subnets** with the CIDR blocks shown in architecture.

### AWS CLI
```bash
# Create Public Subnets
PUBLIC_SUBNET_1=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.10.0.0/24 \
  --availability-zone ap-south-1a \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=ecommerce-public-subnet-1}]' \
  --query 'Subnet.SubnetId' --output text --region ap-south-1)

PUBLIC_SUBNET_2=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.10.1.0/24 \
  --availability-zone ap-south-1b \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=ecommerce-public-subnet-2}]' \
  --query 'Subnet.SubnetId' --output text --region ap-south-1)

# Create Private ECS Subnets
PRIVATE_ECS_SUBNET_1=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.10.10.0/24 \
  --availability-zone ap-south-1a \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=ecommerce-private-ecs-1}]' \
  --query 'Subnet.SubnetId' --output text --region ap-south-1)

PRIVATE_ECS_SUBNET_2=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.10.11.0/24 \
  --availability-zone ap-south-1b \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=ecommerce-private-ecs-2}]' \
  --query 'Subnet.SubnetId' --output text --region ap-south-1)

# Create Private Database Subnets
PRIVATE_DB_SUBNET_1=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.10.20.0/24 \
  --availability-zone ap-south-1a \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=ecommerce-private-database-1}]' \
  --query 'Subnet.SubnetId' --output text --region ap-south-1)

PRIVATE_DB_SUBNET_2=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.10.21.0/24 \
  --availability-zone ap-south-1b \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=ecommerce-private-database-2}]' \
  --query 'Subnet.SubnetId' --output text --region ap-south-1)

# Save subnet IDs
echo "PUBLIC_SUBNET_1=$PUBLIC_SUBNET_1" >> deployment/vpc-resources.txt
echo "PUBLIC_SUBNET_2=$PUBLIC_SUBNET_2" >> deployment/vpc-resources.txt
echo "PRIVATE_ECS_SUBNET_1=$PRIVATE_ECS_SUBNET_1" >> deployment/vpc-resources.txt
echo "PRIVATE_ECS_SUBNET_2=$PRIVATE_ECS_SUBNET_2" >> deployment/vpc-resources.txt
echo "PRIVATE_DB_SUBNET_1=$PRIVATE_DB_SUBNET_1" >> deployment/vpc-resources.txt
echo "PRIVATE_DB_SUBNET_2=$PRIVATE_DB_SUBNET_2" >> deployment/vpc-resources.txt

echo "Created all subnets"
```

## Step 4: Create NAT Gateway

### AWS Console
1. **VPC Console → NAT Gateways → Create NAT gateway**
2. **Name:** `ecommerce-nat-gateway`
3. **Subnet:** ecommerce-public-subnet-1
4. **Connectivity type:** Public
5. **Elastic IP allocation:** Allocate Elastic IP
6. **Create NAT gateway**

### AWS CLI
```bash
# Allocate Elastic IP for NAT Gateway
EIP_ALLOC_ID=$(aws ec2 allocate-address \
  --domain vpc \
  --tag-specifications 'ResourceType=elastic-ip,Tags=[{Key=Name,Value=ecommerce-nat-eip}]' \
  --query 'AllocationId' --output text --region ap-south-1)

# Create NAT Gateway
NAT_GW_ID=$(aws ec2 create-nat-gateway \
  --subnet-id $PUBLIC_SUBNET_1 \
  --allocation-id $EIP_ALLOC_ID \
  --tag-specifications 'ResourceType=nat-gateway,Tags=[{Key=Name,Value=ecommerce-nat-gateway}]' \
  --query 'NatGateway.NatGatewayId' --output text --region ap-south-1)

echo "EIP_ALLOC_ID=$EIP_ALLOC_ID" >> deployment/vpc-resources.txt
echo "NAT_GW_ID=$NAT_GW_ID" >> deployment/vpc-resources.txt
echo "Created NAT Gateway: $NAT_GW_ID"

# Wait for NAT Gateway to be available
echo "Waiting for NAT Gateway to be available..."
aws ec2 wait nat-gateway-available --nat-gateway-ids $NAT_GW_ID --region ap-south-1
```

## Step 5: Create Route Tables

### AWS Console

**Public Route Table:**
1. **VPC Console → Route Tables → Create route table**
2. **Name:** `ecommerce-public-rt`
3. **VPC:** ecommerce-vpc
4. **Create route table**
5. **Routes tab → Edit routes → Add route**
   - Destination: `0.0.0.0/0`
   - Target: Internet Gateway (ecommerce-igw)
6. **Subnet associations tab → Edit subnet associations**
   - Associate both public subnets

**Private ECS Route Table:**
1. **Create route table:** `ecommerce-private-ecs-rt`
2. **Add route:** `0.0.0.0/0` → NAT Gateway
3. **Associate:** Both private ECS subnets

**Private Database Route Table:**
1. **Create route table:** `ecommerce-private-db-rt`
2. **Add route:** `0.0.0.0/0` → NAT Gateway
3. **Associate:** Both private database subnets

### AWS CLI
```bash
# Create Public Route Table
PUBLIC_RT_ID=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=ecommerce-public-rt}]' \
  --query 'RouteTable.RouteTableId' --output text --region ap-south-1)

# Add route to Internet Gateway
aws ec2 create-route \
  --route-table-id $PUBLIC_RT_ID \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id $IGW_ID --region ap-south-1

# Associate public subnets
aws ec2 associate-route-table \
  --route-table-id $PUBLIC_RT_ID \
  --subnet-id $PUBLIC_SUBNET_1 --region ap-south-1

aws ec2 associate-route-table \
  --route-table-id $PUBLIC_RT_ID \
  --subnet-id $PUBLIC_SUBNET_2 --region ap-south-1

# Create Private ECS Route Table
PRIVATE_ECS_RT_ID=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=ecommerce-private-ecs-rt}]' \
  --query 'RouteTable.RouteTableId' --output text --region ap-south-1)

# Add route to NAT Gateway
aws ec2 create-route \
  --route-table-id $PRIVATE_ECS_RT_ID \
  --destination-cidr-block 0.0.0.0/0 \
  --nat-gateway-id $NAT_GW_ID --region ap-south-1

# Associate private ECS subnets
aws ec2 associate-route-table \
  --route-table-id $PRIVATE_ECS_RT_ID \
  --subnet-id $PRIVATE_ECS_SUBNET_1 --region ap-south-1

aws ec2 associate-route-table \
  --route-table-id $PRIVATE_ECS_RT_ID \
  --subnet-id $PRIVATE_ECS_SUBNET_2 --region ap-south-1

# Create Private Database Route Table
PRIVATE_DB_RT_ID=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=ecommerce-private-db-rt}]' \
  --query 'RouteTable.RouteTableId' --output text --region ap-south-1)

# Add route to NAT Gateway
aws ec2 create-route \
  --route-table-id $PRIVATE_DB_RT_ID \
  --destination-cidr-block 0.0.0.0/0 \
  --nat-gateway-id $NAT_GW_ID --region ap-south-1

# Associate private database subnets
aws ec2 associate-route-table \
  --route-table-id $PRIVATE_DB_RT_ID \
  --subnet-id $PRIVATE_DB_SUBNET_1 --region ap-south-1

aws ec2 associate-route-table \
  --route-table-id $PRIVATE_DB_RT_ID \
  --subnet-id $PRIVATE_DB_SUBNET_2 --region ap-south-1

echo "PUBLIC_RT_ID=$PUBLIC_RT_ID" >> deployment/vpc-resources.txt
echo "PRIVATE_ECS_RT_ID=$PRIVATE_ECS_RT_ID" >> deployment/vpc-resources.txt
echo "PRIVATE_DB_RT_ID=$PRIVATE_DB_RT_ID" >> deployment/vpc-resources.txt
echo "Created and configured route tables"
```

## Next Steps
Proceed to **[Module 2: Data Layer](./module2-data-layer.md)** to create the databases.
