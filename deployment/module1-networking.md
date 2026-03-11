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

## Step 2: Create Internet Gateway

### AWS Console
1. **VPC Console → Internet Gateways → Create internet gateway**
2. **Name:** `ecommerce-igw`
3. **Create internet gateway**
4. **Actions → Attach to VPC**
5. **Select:** ecommerce-vpc
6. **Attach internet gateway**

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

## Step 4: Create NAT Gateway

### AWS Console
1. **VPC Console → NAT Gateways → Create NAT gateway**
2. **Name:** `ecommerce-nat-gateway`
3. **Subnet:** ecommerce-public-subnet-1
4. **Connectivity type:** Public
5. **Elastic IP allocation:** Allocate Elastic IP
6. **Create NAT gateway**

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

## Network Architecture Summary

| Subnet Type | Name | CIDR | AZ | Purpose |
|-------------|------|------|----|---------| 
| Public | ecommerce-public-subnet-1 | 10.10.0.0/24 | ap-south-1a | NAT Gateway, Bastion |
| Public | ecommerce-public-subnet-2 | 10.10.1.0/24 | ap-south-1b | Load Balancer (if public) |
| Private ECS | ecommerce-private-ecs-1 | 10.10.10.0/24 | ap-south-1a | ECS Services |
| Private ECS | ecommerce-private-ecs-2 | 10.10.11.0/24 | ap-south-1b | ECS Services |
| Private DB | ecommerce-private-database-1 | 10.10.20.0/24 | ap-south-1a | RDS Primary |
| Private DB | ecommerce-private-database-2 | 10.10.21.0/24 | ap-south-1b | RDS Standby |

## Next Steps
Proceed to **[Module 2: Data Layer](./module2-data-layer.md)** to create the databases.
