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

- Docker & Docker Compose
- Node.js 16+ and npm
- AWS CLI (for LocalStack)
- AWS Cognito User Pool (for authentication)

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

Note: Depending on your environment you may have to use "docker compose" instead of "docker-compose" command.
```
This starts:
- LocalStack (DynamoDB, SNS, SQS, SES)
- PostgreSQL
- 5 microservices (product, cart, user, order, notification)
- Nginx (API gateway on port 8080)

### 4. Load Product Data

```bash
cd local-deployment/data
bash load-products-local.sh <region>

Example: bash load-products-local.sh ap-south-1

```

This loads 20 sample products into DynamoDB.

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
4. Add items to cart
5. Place an order

## API Endpoints

All APIs available at `http://localhost:8080/api`:

- `GET /api/products` - List all products
- `GET /api/cart` - Get user's cart
- `POST /api/cart` - Add item to cart
- `GET /api/users/profile` - Get user profile
- `POST /api/users/profile` - Create/update profile
- `GET /api/orders` - List user's orders
- `POST /api/orders` - Create new order

## Verify Services

```bash
# Check all containers are running
docker compose ps

# Check product count
aws dynamodb scan --table-name products --endpoint-url http://localhost:4566 --region us-east-1 --query 'Count'

# Check PostgreSQL
docker compose exec postgres psql -U postgres -d ecommercedb -c "\dt"

# Test API
curl http://localhost:8080/api/products
```

## Troubleshooting

### CORS Errors
The nginx configuration allows all origins. If you see CORS errors, restart nginx:
```bash
docker compose restart nginx
```

### Database Issues
Reset PostgreSQL tables:
```bash
docker compose exec postgres psql -U postgres -d ecommercedb -c "DROP TABLE IF EXISTS order_items CASCADE; DROP TABLE IF EXISTS orders CASCADE; DROP TABLE IF EXISTS users CASCADE;"
docker compose restart user-service order-service
```

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
docker compose down -v
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
