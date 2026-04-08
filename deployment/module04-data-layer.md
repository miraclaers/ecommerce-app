# Module 4: Data Layer

## Overview
Let's set up the data storage and databases for the application.

## In this module
- Upload product images to S3 bucket. Images will be served through Amazon CloudFront for caching and optimized delivery.
- Create DynamoDB tables for storing products data and cart.
- Create RDS PostgreSQL relational database for storing users, orders data.
- Create parameters in Systems Manager Parameter Store for storing the configurations such as database host, username/password for microservices to read from.

## 4.1 Upload Product Images to S3 bucket

We will use the same frontend bucket for product images as well.
There are some sample images under data/product-images/ directory. You can run following script to upload these images to your S3 bucket.

**Using Upload Script:**
```bash
# Run from the repo root directory
cd data
bash upload-images-to-s3.sh <your-bucket-name>
```

This script uploads sample product images (prod-001.jpg through prod-020.jpg) to your S3 bucket.

**Verify that you are able to access the images publicly over the browser using CloudFront URL:**
```
Example: https://dhzk1s0exnne1.cloudfront.net/images/products/prod-001.jpg
```

## 4.2 DynamoDB - NoSQL Database

### Create Products Table

1. **DynamoDB Console → Tables → Create table**
2. **Table name:** `ecommerce-products`
3. **Partition key:** `product_id` (String)
4. **Sort key:** Leave empty (no sort key needed)
5. **Table class:** DynamoDB Standard
6. **Capacity mode:** On-demand
7. **Create table**

### Create Cart Table

1. **DynamoDB Console → Tables → Create table**
2. **Table name:** `ecommerce-cart`
3. **Partition key:** `user_id` (String)
4. **Sort key:** Leave empty (no sort key needed)
5. **Table class:** DynamoDB Standard
6. **Capacity mode:** On-demand
7. **Create table**

<details>
<summary><strong>CLI equivalent</strong></summary>

```bash
aws dynamodb create-table \
  --table-name ecommerce-products \
  --attribute-definitions AttributeName=product_id,AttributeType=S \
  --key-schema AttributeName=product_id,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST

aws dynamodb create-table \
  --table-name ecommerce-cart \
  --attribute-definitions AttributeName=user_id,AttributeType=S \
  --key-schema AttributeName=user_id,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

</details>


### Load Sample Products Data

There is a sample data file products.json in the repo which contains data for 20 products. The data is in the following format:
```json
{
  "product_id": "prod-001",
  "name": "Wireless Bluetooth Headphones",
  "description": "Premium noise-cancelling over-ear headphones",
  "price": 89.99,
  "stock": 150,
  "image_url": "https://example.com/images/products/prod-001.jpg",
  "category": "Electronics"
}
```

As you can see the data for each product also contains product image URL (dummy). Hence, first we need to update the products.json file with Product image URLs that we will use in our application. The URL should be the CloudFront URL for each imagae that you just verified after uploading images to S3.

**Step 1: Update Product Image URLs**
```bash
# Run from the repo root directory
cd data
bash update-product-image-urls.sh <cloudfront URL>
```

Example:
```bash
bash update-product-image-urls.sh https://dhzk1s0exnne1.cloudfront.net
```

This script updates all image URLs in `products.json` file. We will now use this file to update the DynamoDB table.

**Step 2: Load Products into DynamoDB**

```bash
bash load-products.sh <your-region>
```

This script loads 20 sample products from the updated `products.json` into your DynamoDB ecommerce-products table.

**Step 3: Verify that DynamoDB table is updated**

Go to DynamoDB -> ecommerce_products table and check if you see 20 products data with updated image URLs.

## 2.3 RDS - PostgreSQL Database

### Create DB Subnet Group

1. **RDS Console → Subnet groups → Create DB subnet group**
2. **Name:** `ecommerce-db-subnet-group`
3. **Description:** "Subnet group for ecommerce RDS"
4. **VPC:** Select `ecommerce-vpc`
5. **Add subnets:**
   - Select both availability zones (ap-south-1a, ap-south-1b)
   - Select both private database subnets
6. **Create**

### Create Security Group for RDS

1. **VPC Console → Security Groups → Create security group**
2. **Name:** `ecommerce-rds-sg`
3. **Description:** "Security group for RDS PostgreSQL"
4. **VPC:** Select `ecommerce-vpc`
5. **Inbound rules:**
   - Type: PostgreSQL
   - Port: 5432
   - Source: Custom - 10.10.0.0/16 (VPC CIDR)
   - Description: "Allow PostgreSQL from VPC"
6. **Outbound rules:** Keep default (all traffic)
7. **Create**

### Create RDS Instance

1. **RDS Console → Databases → Create database**
2. **Engine options:**
   - Engine type: PostgreSQL
3. **Choose a database creation method:** Full configuration
4. **Templates:** Free Tier or Dev/Test
5. **Settings:**
   - DB instance identifier: **`ecommercedb-instance`**
   - Master username: `postgres`
   - Master password: (create a password - remember or save it!)
6. **Database authentication:** Password authentication
7. **Instance configuration:**
   - DB instance class: Burstable classes - db.t3.micro
8. **Connectivity:**
   - VPC: `ecommerce-vpc`
   - DB subnet group: `ecommerce-db-subnet-group`
   - Public access: No
   - VPC security group: Choose existing - `ecommerce-rds-sg`
   - Availability Zone: Choose first AZ
9. **Monitoring:**
   - Uncheck "Enable Performance Insights" (We don't need this for Dev/Test database)
10. **Additional configuration:**
    - **IMPORTANT:** Initial database name: **`ecommercedb`** (This is critical - don't skip!)
    - Uncheck "Enable automated backups" (We don't need this for Dev/Test database)
    - Uncheck "Enable encryption" (We don't need this for Dev/Test database)
11. **Create database** (takes 5-10 minutes)

<details>
<summary><strong>CLI equivalent</strong></summary>

```bash
# Create RDS security group
RDS_SG=$(aws ec2 create-security-group \
  --group-name ecommerce-rds-sg \
  --description "Security group for RDS PostgreSQL" \
  --vpc-id $VPC_ID \
  --query 'GroupId' --output text)

aws ec2 authorize-security-group-ingress \
  --group-id $RDS_SG \
  --protocol tcp --port 5432 \
  --cidr 10.10.0.0/16

# Create DB subnet group
aws rds create-db-subnet-group \
  --db-subnet-group-name ecommerce-db-subnet-group \
  --db-subnet-group-description "Subnet group for ecommerce RDS" \
  --subnet-ids $DB_SUBNET_1 $DB_SUBNET_2

# Set your DB password
DB_PASSWORD="YourSecurePass123!"

# Create RDS instance
aws rds create-db-instance \
  --db-instance-identifier ecommercedb-instance \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --master-username postgres \
  --master-user-password $DB_PASSWORD \
  --db-name ecommercedb \
  --db-subnet-group-name ecommerce-db-subnet-group \
  --vpc-security-group-ids $RDS_SG \
  --no-publicly-accessible \
  --no-enable-performance-insights \
  --backup-retention-period 0 \
  --allocated-storage 20 \
  --no-storage-encrypted \
  --availability-zone ap-south-1a

# Wait for RDS to become available (takes 5-10 minutes)
echo "Waiting for RDS instance to become available (this takes 5-10 minutes)..."
aws rds wait db-instance-available --db-instance-identifier ecommercedb-instance
echo "RDS instance is ready!"

# Get RDS endpoint
RDS_ENDPOINT=$(aws rds describe-db-instances \
  --db-instance-identifier ecommercedb-instance \
  --query 'DBInstances[0].Endpoint.Address' --output text)

echo "RDS_ENDPOINT=$RDS_ENDPOINT"
echo "DB_PASSWORD=$DB_PASSWORD"
```

</details>

<details>
<summary><strong>📋 Database Schema - Just for the reference (Click to expand)</strong></summary>

**The database tables will be automatically created by each microservice on startup. We don't need to create it.**

**Users Table** (user-service):
```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    cognito_sub VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) NOT NULL,
    name VARCHAR(255),
    phone VARCHAR(50),
    address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Orders Table** (order-service):
```sql
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    user_email VARCHAR(255) NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(id),
    product_id VARCHAR(255) NOT NULL,
    quantity INTEGER NOT NULL,
    price DECIMAL(10, 2) NOT NULL
);
```

</details>

## 2.4 Parameter Store - Configuration Management

### Create Database Configuration Parameters

After the RDS instance is created, store the database configuration in Parameter Store for secure access by microservices:

1. **Systems Manager Console → Parameter Store → Create parameter**

**AWS Region Parameter:**
- **Name:** `/ecommerce/dev/aws/region`
- **Type:** String
- **Value:** `<your-aws-region>` (e.g. ap-south-1 or us-east-1)

**Database Host Parameter:**
- **Name:** `/ecommerce/dev/db/host`
- **Type:** String
- **Value:** `<your-rds-endpoint>` (from RDS Console → Databases → ecommerce-db → Endpoint)

**Database Password Parameter:**
- **Name:** `/ecommerce/dev/db/password`
- **Type:** SecureString
- **Value:** `<your-database-password>`

These parameters will be automatically loaded by the user-service and order-service when deployed to ECS.

<details>
<summary><strong>CLI equivalent</strong></summary>

```bash
# Retrieve values dynamically
AWS_REGION=$(aws configure get region)

RDS_ENDPOINT=$(aws rds describe-db-instances \
  --db-instance-identifier ecommercedb-instance \
  --query 'DBInstances[0].Endpoint.Address' --output text)

echo "AWS_REGION=$AWS_REGION"
echo "RDS_ENDPOINT=$RDS_ENDPOINT"
echo "DB_PASSWORD=$DB_PASSWORD"

# Create Parameter Store parameters
aws ssm put-parameter \
  --name /ecommerce/dev/aws/region \
  --type String \
  --value $AWS_REGION

aws ssm put-parameter \
  --name /ecommerce/dev/db/host \
  --type String \
  --value $RDS_ENDPOINT

aws ssm put-parameter \
  --name /ecommerce/dev/db/password \
  --type SecureString \
  --value $DB_PASSWORD
```

</details>

## Next Steps
Proceed to **[Module 5: Backend Deployment](./module05-backend-deployment.md)**
