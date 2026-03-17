# AWS eCommerce Tutorial - Local Deployment

A microservices-based eCommerce application running locally with LocalStack (AWS emulator).

## Architecture

### Services
- **Product Service** - Product catalog (DynamoDB)
- **Cart Service** - Shopping cart (DynamoDB)
- **User Service** - User profiles (PostgreSQL)
- **Order Service** - Order processing (PostgreSQL)
- **Notification Service** - Email notifications (SNS/SQS/SES)

### Tech Stack
- **Backend**: Python FastAPI microservices
- **Frontend**: React application
- **Database**: PostgreSQL + DynamoDB (LocalStack)
- **Auth**: AWS Cognito User Pools
- **Messaging**: SNS + SQS (LocalStack)
- **API Gateway**: Nginx (simulates AWS ALB)

## Prerequisites

### 1. AWS Account
- An AWS account (needed for Cognito authentication)

### 2. Local Workstation (Linux / Mac)
- A Linux or macOS machine
- Windows users can use WSL2 (Ubuntu)

### 3. Required Tools
- **Git** — version control
- **Docker** and **Docker Compose** — for running services locally
- **Node.js 20+** and **npm** — for the React frontend
- **AWS CLI v2** — for interacting with LocalStack

### Step 1: Clone the Repository

```bash
git clone https://github.com/awswithchetan/ecommerce-web-app.git
cd ecommerce-web-app
```

### Step 2: Install Required Tools

**Option 1: Automated (Recommended)**
```bash
bash install-prerequisites.sh
```

**Option 2: Manual** — install Git, Docker, Node.js 20+, and AWS CLI v2 individually for your OS.

### Step 3: Verify

```bash
aws --version
docker --version
node --version
git --version
```

---

## Quick Start

### 1. Set Up AWS Cognito

Create a Cognito User Pool for authentication:

1. Go to **AWS Cognito Console** → **User pools** → **Create user pool**

2. **Define your application**: Select **Single-page application (SPA)**

3. **Name your application**: Enter `ecommerce-app` (or your preferred name)

4. **Configure options**:
   - **Options for sign-in identifiers**: Select **Email**
   - **Self-registration**: Enable
   - **Required attributes for sign-up**: Select **email** and **name**

5. **Add a return URL**: `http://localhost:3000`

6. Click **Create user directory**

7. **Configure App Client Authentication**:
   - Go to your newly created User Pool → **App integration** tab → **App clients**
   - Click on your app client name
   - Under **Authentication flows**, enable:
     - ✅ **ALLOW_USER_PASSWORD_AUTH**
     - ✅ **ALLOW_USER_SRP_AUTH** 
     - ✅ **ALLOW_REFRESH_TOKEN_AUTH**
   - Click **Save changes**

This automatically creates both the User Pool and App Client. Note down:
- **User Pool ID** (e.g., `ap-south-1_xxxxxxxxx`)
- **App Client ID** (e.g., `1a2b3c4d5e6f7g8h9i0j1k2l3m`)
- **Cognito Domain** (if you set up a custom domain)
   - Advanced app client settings:
     - OAuth 2.0 grant types: **Authorization code grant**
     - OpenID Connect scopes: **OpenID, Email, Profile**
     - Authentication flows: Enable the following:
       - ✅ **ALLOW_USER_PASSWORD_AUTH**
       - ✅ **ALLOW_USER_SRP_AUTH**
       - ✅ **ALLOW_REFRESH_TOKEN_AUTH**
   - Click **Next**

7. **Review and create:**
   - Review all settings
   - Click **Create user pool**

8. **Note down the following values** (you'll need these for frontend configuration):
   - **User Pool ID** (from User pool overview)
   - **App Client ID** (from App integration → App client list)
   - **Cognito Domain** (from App integration → Domain)

### 2. Configure Frontend

Edit `frontend/react-app/src/aws-config.js`:

```javascript
const awsConfig = {
  Auth: {
    Cognito: {
      userPoolId: 'ap-south-1_xxxxxxxxx',      // Your actual User Pool ID
      userPoolClientId: '1a2b3c4d5e6f7g8h9i0j1k2l3m',    // Your actual App Client ID
      loginWith: {
        email: true,
      },
    }
  }
};
```

### 3. Start Backend Services

```bash
cd local-deployment
AWS_REGION=<region> docker-compose up -d

Example: AWS_REGION=ap-south-1 docker-compose up -d

Depending on your environment you may have to use "docker compose" instead of "docker-compose" command.
```
> This may take upto 5-10 mins, so have a break :)

This starts:
- LocalStack (DynamoDB, SNS, SQS, SES)
- PostgreSQL
- 5 microservices (product, cart, user, order, notification)
- Nginx (API gateway on port 8080)

**Verify if all the containers are running**
```
docker ps
>
CONTAINER ID   IMAGE                                   COMMAND                  CREATED         STATUS                   PORTS                                                                  NAMES
aff0fde1b304   nginx:alpine                            "/docker-entrypoint.…"   5 minutes ago   Up 5 minutes             0.0.0.0:8080->80/tcp, [::]:8080->80/tcp                                local-deployment_nginx_1
8c5cba392f03   local-deployment_order-service          "uvicorn main:app --…"   5 minutes ago   Up 5 minutes             0.0.0.0:8004->8004/tcp, [::]:8004->8004/tcp                            local-deployment_order-service_1
8a4a59cde696   local-deployment_user-service           "uvicorn main:app --…"   5 minutes ago   Up 5 minutes             0.0.0.0:8003->8003/tcp, [::]:8003->8003/tcp                            local-deployment_user-service_1
dc84392556a1   local-deployment_cart-service           "uvicorn main:app --…"   5 minutes ago   Up 5 minutes             0.0.0.0:8002->8002/tcp, [::]:8002->8002/tcp                            local-deployment_cart-service_1
7627063244b1   local-deployment_notification-service   "python main.py"         5 minutes ago   Up 5 minutes                                                                                    local-deployment_notification-service_1
3ec638edcc9d   local-deployment_product-service        "uvicorn main:app --…"   5 minutes ago   Up 5 minutes             0.0.0.0:8001->8001/tcp, [::]:8001->8001/tcp                            local-deployment_product-service_1
620027be435c   localstack/localstack:latest            "docker-entrypoint.sh"   5 minutes ago   Up 5 minutes (healthy)   4510-4559/tcp, 5678/tcp, 0.0.0.0:4566->4566/tcp, [::]:4566->4566/tcp   local-deployment_localstack_1
e432c4499cd5   postgres:15-alpine                      "docker-entrypoint.s…"   5 minutes ago   Up 5 minutes (healthy)   0.0.0.0:5433->5432/tcp, [::]:5433->5432/tcp                            local-deployment_postgres_1
```
### 4. Load Product Data

```bash
cd local-deployment/data
bash load-products-local.sh <region>

Example: bash load-products-local.sh ap-south-1

```

This loads 20 sample products into local DynamoDB.

### 5. Start Frontend

```bash
cd frontend/react-app
npm install
npm start
```

Frontend runs on http://localhost:3000

### 6. Test the Application

1. Open http://localhost:3000
2. Sign up with email/password
3. Browse products
4. Add items to cart -> Scroll up to the Cart
5. Place an order
6. Check the Orders tab
7. Check notification -> For local deployment, there should be an order file created under local-deployment/emails directory.
```
chetan@LAPTOP-DATTECKB:~/ecommerce-web-app/local-deployment/emails$ cat order_1_20260312_051039.txt
To: xxxxxx@xxxx.xxx
Subject: Order Confirmation - #1


    Order Confirmation

    Thank you for your order!

    Order ID: 1
    Total Amount: $299.97

    Items:

- Product: prod-015, Quantity: 1, Price: $19.99
- Product: prod-016, Quantity: 1, Price: $249.99
- Product: prod-012, Quantity: 1, Price: $29.99
```

## API Endpoints

All APIs available at `http://localhost:8080/api`:

- `GET /api/products` - List all products
- `GET /api/cart` - Get user's cart
- `POST /api/cart` - Add item to cart
- `GET /api/users/profile` - Get user profile
- `POST /api/users/profile` - Create/update profile
- `GET /api/orders` - List user's orders
- `POST /api/orders` - Create new order

## Troubleshooting

### LocalStack Issues
Restart LocalStack:
```bash
docker-compose restart localstack
cd data && ./load-products-local.sh
```

### Images Not Loading
Verify nginx is serving images:
```bash
curl -I http://localhost:8080/images/prod-001.jpg
```

## Clean Up

```bash
cd local-deployment
docker-compose down -v
```

This removes all containers and volumes.

## Project Structure

```
ecommerce-aws-tutorial/
├── services/               # Backend microservices
│   ├── product-service/
│   ├── cart-service/
│   ├── user-service/
│   ├── order-service/
│   └── notification-service/
├── frontend/
│   └── react-app/         # React frontend
└── local-deployment/
    ├── docker-compose.yml
    ├── nginx.conf
    ├── data/
    │   ├── products-local.json
    │   ├── product-images/
    │   └── load-products-local.sh
    └── localstack-init/
```

## Development

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f product-service
```

### Rebuild Services

```bash
docker-compose up -d --build
```

### Access Databases

```bash
# PostgreSQL
docker-compose exec postgres psql -U postgres -d ecommercedb

# DynamoDB (via AWS CLI)
aws dynamodb scan --table-name products --endpoint-url http://localhost:4566 --region <region>
```

## License

MIT
