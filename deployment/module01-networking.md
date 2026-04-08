# Module 1: Networking Foundation

## Overview
Create VPC infrastructure with public and private subnets across 2 availability zones for the ecommerce application.

## In this module
- **VPC** - Virtual Private Cloud with 10.10.0.0/16 CIDR
- **Public Subnets** - 2 subnets for internet-facing resources (NAT Gateway, Bastion)
- **Private ECS Subnets** - 2 subnets for application services
- **Private Database Subnets** - 2 subnets for RDS instances
- **Internet Gateway** - Internet access for public subnets
- **NAT Gateway** - Outbound internet access for private subnets
- **Route Tables** - Traffic routing configuration

**Note:** This guide assumes the AWS region to be Mumbai (ap-south-1). You can choose your region and select the AZs accordingly.

## Architecture
<img width="800" height="1080" alt="image" src="https://github.com/user-attachments/assets/f471f7d3-e47b-4988-8585-ba3555387ed3" />

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

## 1.1: Create VPC

1. **VPC Console → Your VPCs → Create VPC**
2. **Name:** `ecommerce-vpc`
3. **IPv4 CIDR block:** `10.10.0.0/16`
4. **IPv6 CIDR block:** No IPv6 CIDR block
5. **Tenancy:** Default
6. **Create VPC**

<details>
<summary><strong>CLI equivalent</strong></summary>

```bash
VPC_ID=$(aws ec2 create-vpc \
  --cidr-block 10.10.0.0/16 \
  --query 'Vpc.VpcId' --output text)

aws ec2 create-tags \
  --resources $VPC_ID \
  --tags Key=Name,Value=ecommerce-vpc

echo "VPC_ID=$VPC_ID"
```

</details>

## 1.2: Create Internet Gateway

1. **VPC Console → Internet Gateways → Create internet gateway**
2. **Name:** `ecommerce-igw`
3. **Create internet gateway**
4. **Actions → Attach to VPC**
5. **Select:** ecommerce-vpc
6. **Attach internet gateway**

<details>
<summary><strong>CLI equivalent</strong></summary>

```bash
IGW_ID=$(aws ec2 create-internet-gateway \
  --query 'InternetGateway.InternetGatewayId' --output text)

aws ec2 create-tags \
  --resources $IGW_ID \
  --tags Key=Name,Value=ecommerce-igw

aws ec2 attach-internet-gateway \
  --internet-gateway-id $IGW_ID \
  --vpc-id $VPC_ID

echo "IGW_ID=$IGW_ID"
```

</details>

## 1.3: Create Subnets

**Public Subnet 1:**
1. **VPC Console → Subnets → Create subnet**
2. **VPC:** ecommerce-vpc
3. **Name:** `ecommerce-public-subnet-1`
4. **Availability Zone:** ap-south-1a
5. **IPv4 CIDR block:** `10.10.0.0/24`
6. **Create subnet**

**Repeat for all 6 subnets** with the CIDR blocks as per the table below:
| Subnet Type | Name | CIDR | AZ | Purpose |
|-------------|------|------|----|---------| 
| Public | ecommerce-public-subnet-1 | 10.10.0.0/24 | ap-south-1a | NAT Gateway, Bastion host |
| Public | ecommerce-public-subnet-2 | 10.10.1.0/24 | ap-south-1b | NAT Gateway, Bastion host (For HA setup if required)|
| Private ECS | ecommerce-private-ecs-1 | 10.10.10.0/24 | ap-south-1a | ECS Services, Internal ALB, APIGW VPCLink |
| Private ECS | ecommerce-private-ecs-2 | 10.10.11.0/24 | ap-south-1b | ECS Services, Internal ALB, APIGW VPCLink |
| Private DB | ecommerce-private-database-1 | 10.10.20.0/24 | ap-south-1a | RDS Primary |
| Private DB | ecommerce-private-database-2 | 10.10.21.0/24 | ap-south-1b | RDS Standby (For HA setup if required)|

<details>
<summary><strong>CLI equivalent</strong></summary>

```bash
# Public subnets
PUB_SUBNET_1=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID --cidr-block 10.10.0.0/24 \
  --availability-zone ap-south-1a \
  --query 'Subnet.SubnetId' --output text)
aws ec2 create-tags --resources $PUB_SUBNET_1 \
  --tags Key=Name,Value=ecommerce-public-subnet-1

PUB_SUBNET_2=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID --cidr-block 10.10.1.0/24 \
  --availability-zone ap-south-1b \
  --query 'Subnet.SubnetId' --output text)
aws ec2 create-tags --resources $PUB_SUBNET_2 \
  --tags Key=Name,Value=ecommerce-public-subnet-2

# Private ECS subnets
ECS_SUBNET_1=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID --cidr-block 10.10.10.0/24 \
  --availability-zone ap-south-1a \
  --query 'Subnet.SubnetId' --output text)
aws ec2 create-tags --resources $ECS_SUBNET_1 \
  --tags Key=Name,Value=ecommerce-private-ecs-1

ECS_SUBNET_2=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID --cidr-block 10.10.11.0/24 \
  --availability-zone ap-south-1b \
  --query 'Subnet.SubnetId' --output text)
aws ec2 create-tags --resources $ECS_SUBNET_2 \
  --tags Key=Name,Value=ecommerce-private-ecs-2

# Private DB subnets
DB_SUBNET_1=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID --cidr-block 10.10.20.0/24 \
  --availability-zone ap-south-1a \
  --query 'Subnet.SubnetId' --output text)
aws ec2 create-tags --resources $DB_SUBNET_1 \
  --tags Key=Name,Value=ecommerce-private-database-1

DB_SUBNET_2=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID --cidr-block 10.10.21.0/24 \
  --availability-zone ap-south-1b \
  --query 'Subnet.SubnetId' --output text)
aws ec2 create-tags --resources $DB_SUBNET_2 \
  --tags Key=Name,Value=ecommerce-private-database-2

echo "PUB_SUBNET_1=$PUB_SUBNET_1  PUB_SUBNET_2=$PUB_SUBNET_2"
echo "ECS_SUBNET_1=$ECS_SUBNET_1  ECS_SUBNET_2=$ECS_SUBNET_2"
echo "DB_SUBNET_1=$DB_SUBNET_1    DB_SUBNET_2=$DB_SUBNET_2"
```

</details>

## 1.4: Create NAT Gateway

1. **VPC Console → NAT Gateways → Create NAT gateway**
2. **Name:** `ecommerce-nat-gateway`
3. **Availability Mode:** Zonal
4. **Subnet:** ecommerce-public-subnet-1
5. **Connectivity type:** Public
6. **Elastic IP allocation:** Allocate Elastic IP
7. **Create NAT gateway**

<details>
<summary><strong>CLI equivalent</strong></summary>

```bash
EIP_ALLOC=$(aws ec2 allocate-address \
  --domain vpc \
  --query 'AllocationId' --output text)

NAT_GW_ID=$(aws ec2 create-nat-gateway \
  --subnet-id $PUB_SUBNET_1 \
  --allocation-id $EIP_ALLOC \
  --query 'NatGateway.NatGatewayId' --output text)

aws ec2 create-tags \
  --resources $NAT_GW_ID \
  --tags Key=Name,Value=ecommerce-nat-gateway

# Wait for NAT Gateway to become available before creating route tables
aws ec2 wait nat-gateway-available --nat-gateway-ids $NAT_GW_ID

echo "NAT_GW_ID=$NAT_GW_ID"
```

</details>

## 1.5: Create Route Tables

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
2. **No new route required**
3. **Associate:** Both private database subnets

<details>
<summary><strong>CLI equivalent</strong></summary>

```bash
# Public route table
PUB_RT=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-tags --resources $PUB_RT \
  --tags Key=Name,Value=ecommerce-public-rt
aws ec2 create-route \
  --route-table-id $PUB_RT \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id $IGW_ID
aws ec2 associate-route-table --route-table-id $PUB_RT --subnet-id $PUB_SUBNET_1
aws ec2 associate-route-table --route-table-id $PUB_RT --subnet-id $PUB_SUBNET_2

# Private ECS route table
ECS_RT=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-tags --resources $ECS_RT \
  --tags Key=Name,Value=ecommerce-private-ecs-rt
aws ec2 create-route \
  --route-table-id $ECS_RT \
  --destination-cidr-block 0.0.0.0/0 \
  --nat-gateway-id $NAT_GW_ID
aws ec2 associate-route-table --route-table-id $ECS_RT --subnet-id $ECS_SUBNET_1
aws ec2 associate-route-table --route-table-id $ECS_RT --subnet-id $ECS_SUBNET_2

# Private DB route table (no internet route needed)
DB_RT=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-tags --resources $DB_RT \
  --tags Key=Name,Value=ecommerce-private-db-rt
aws ec2 associate-route-table --route-table-id $DB_RT --subnet-id $DB_SUBNET_1
aws ec2 associate-route-table --route-table-id $DB_RT --subnet-id $DB_SUBNET_2
```

</details>

## Next Steps
Proceed to **[Module 2: Authentication](./module02-cognito-authentication.md)**
