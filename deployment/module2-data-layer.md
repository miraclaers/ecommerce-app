# Module 2: Data Layer

## Overview
Set up the data storage layer for the ecommerce application:
- **S3** for product images with public read access
- **DynamoDB** for high-performance NoSQL data (products, cart)
- **RDS PostgreSQL** for relational data (users, orders) in private subnets
- **Parameter Store** for database configuration management

This module creates the foundation for data storage across all microservices with proper security and performance considerations.

---

## 2.1 S3 - Product Images Storage

### Create S3 Bucket

1. **S3 Console → Buckets → Create bucket**
2. **Bucket name:** `ecommerce-product-images-<random-number>` (must be globally unique)
3. **Region:** Choose your preferred region
4. **Block all public access:** **Uncheck** (we need public read for images)
5. **Acknowledge the warning**
6. **Bucket versioning:** Disable
7. **Encryption:** Enable (SSE-S3)
8. **Create bucket**

### Configure Public Read Access

**Bucket Policy:**
1. **Go to bucket → Permissions → Bucket policy**
2. **Add policy:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::ecommerce-product-images-<your-bucket-name>/*"
    }
  ]
}
```

**CORS Configuration:**
1. **Go to bucket → Permissions → CORS**
2. **Add configuration:**
```json
[
  {
    "AllowedHeaders": ["*"],
    "AllowedMethods": ["GET", "HEAD"],
    "AllowedOrigins": ["*"],
    "ExposeHeaders": []
  }
]
```

### Upload Product Images

**Using Upload Script:**
```bash
cd data
./upload-images-to-s3.sh ecommerce-product-images-<your-bucket-name>
```

This script uploads sample product images (prod-001.jpg through prod-020.jpg) to your S3 bucket.

**Manual Upload:**
1. **Go to S3 bucket → Upload**
2. **Add files** (name them: prod-001.jpg, prod-002.jpg, etc.)
3. **Upload**

**Image URL Format:**
```
https://ecommerce-product-images-<bucket-name>.s3.<your-region>.amazonaws.com/prod-001.jpg
```

---

## 2.2 DynamoDB - NoSQL Tables

### Products Table

1. **DynamoDB Console → Tables → Create table**
2. **Table name:** `ecommerce-products`
3. **Partition key:** `product_id` (String)
4. **Table settings:** Customize settings
5. **Table class:** DynamoDB Standard
6. **Capacity mode:** On-demand
7. **Encryption:** Amazon DynamoDB owned key
8. **Create table**

### Cart Table

1. **DynamoDB Console → Tables → Create table**
2. **Table name:** `ecommerce-cart`
3. **Partition key:** `user_id` (String)
4. **Sort key:** `product_id` (String)
5. **Table settings:** Customize settings
6. **Capacity mode:** On-demand
7. **Encryption:** Amazon DynamoDB owned key
8. **Create table**

### Load Sample Products Data

**Step 1: Update Product Image URLs**

First, update the products.json file with your S3 bucket URLs:

```bash
cd data
./update-product-image-urls.sh ecommerce-product-images-<your-bucket-name> <your-region>
```

Example:
```bash
./update-product-image-urls.sh ecommerce-product-images-12345 ap-south-1
```

This script:
- Updates all image URLs in `products.json` to point to your S3 bucket
- Creates a backup of the original file
- Shows a sample URL for verification

**Step 2: Load Products into DynamoDB**

```bash
./load-products.sh <your-region>
```

This script loads 20 sample products from the updated `data/products.json` into your DynamoDB table.

**Manual Data Entry:**
1. **Go to DynamoDB Console → Tables → ecommerce-products**
2. **Actions → Create item**
3. **Add sample product:**
```json
{
  "product_id": "prod-001",
  "name": "Wireless Bluetooth Headphones",
  "description": "Premium noise-cancelling over-ear headphones",
  "price": 89.99,
  "stock": 150,
  "image_url": "https://ecommerce-product-images-<bucket-name>.s3.<your-region>.amazonaws.com/prod-001.jpg",
  "category": "Electronics"
}
```

---

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
2. **Choose creation method:** Standard create
3. **Engine options:**
   - Engine type: PostgreSQL
   - Version: PostgreSQL 15.x (latest)
4. **Templates:** Dev/Test
5. **Settings:**
   - DB instance identifier: `ecommerce-db`
   - Master username: `postgres`
   - Master password: (create strong password - save it!)
6. **Instance configuration:**
   - DB instance class: Burstable classes - db.t3.micro
7. **Connectivity:**
   - VPC: `ecommerce-vpc`
   - DB subnet group: `ecommerce-db-subnet-group`
   - Public access: No
   - VPC security group: Choose existing - `ecommerce-rds-sg`
   - Availability Zone: No preference (Single-AZ for Dev/Test)
8. **Database authentication:** Password authentication
9. **Monitoring:**
   - **❌ Uncheck "Enable Enhanced Monitoring"** (to reduce costs)
10. **Additional configuration:**
    - **⚠️ IMPORTANT:** Initial database name: `ecommercedb` (This is critical - don't skip!)
    - **❌ Uncheck "Enable automated backups"** (Backup retention period: 0 days)
    - **❌ Uncheck "Enable encryption"** (to simplify tutorial setup)
11. **Create database** (takes 5-10 minutes)

<details>
<summary><strong>📋 Database Schema Reference (Click to expand)</strong></summary>

The database schema will be automatically created by each microservice on startup:

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

---

## 2.4 Parameter Store - Configuration Management

### Create Database Configuration Parameters

After the RDS instance is created, store the database configuration in Parameter Store for secure access by microservices:

1. **Systems Manager Console → Parameter Store → Create parameter**

**Database Host Parameter:**
- **Name:** `/ecommerce/dev/db/host`
- **Type:** String
- **Value:** `<your-rds-endpoint>` (from RDS Console → Databases → ecommerce-db → Endpoint)

**Database Password Parameter:**
- **Name:** `/ecommerce/dev/db/password`
- **Type:** SecureString
- **Value:** `<your-database-password>`

These parameters will be automatically loaded by the user-service and order-service when deployed to ECS.

## Next Steps
Proceed to **[Module 3: Authentication](./module3-authentication.md)** to set up Cognito User Pools.
