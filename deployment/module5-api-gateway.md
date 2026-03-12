# Module 5: API Gateway with VPC Link

## Overview
Create an HTTP API Gateway that connects to the internal Application Load Balancer using VPC Link, providing a public endpoint for the frontend application to access all microservices.

## What We'll Build
- **5.1** VPC Link for secure connection to internal ALB
- **5.2** HTTP API Gateway with $default stage
- **5.3** Single HTTP proxy integration to internal ALB
- **5.4** JWT Authorizer for Cognito authentication
- **5.5** Three API routes: public products, authenticated proxy, and CORS
- **5.6** CORS configuration for frontend access
- **5.7** API endpoint testing with mixed authentication
- **5.8** Parameter Store configuration for API URL

## Architecture
```
Internet → API Gateway → VPC Link → Internal ALB → ECS Services
```

The API Gateway will have three specific routes:
- `GET /products` → Product Service (public, no auth)
- `ANY /{proxy+}` → All Services (authenticated, JWT required)
- `OPTIONS /{proxy+}` → CORS preflight (public, no auth)

---

## 5.1 Create VPC Link

### VPC Link Configuration

1. **API Gateway Console → VPC Links → Create VPC Link**
2. **Name:** `ecommerce-vpc-link`
3. **Description:** "VPC Link for ecommerce internal ALB"
4. **Target:** Application Load Balancer
5. **Load balancer:** Select `ecommerce-internal-alb`
6. **Create VPC Link**

**Note:** VPC Link creation takes 5-10 minutes. Wait for status to become "Available" before proceeding.

---

## 5.2 Create HTTP API Gateway

### API Gateway Configuration

1. **API Gateway Console → APIs → Create API**
2. **Choose:** HTTP API → Build
3. **API name:** `ecommerce-api`
4. **Description:** "eCommerce HTTP API"
5. **Next**

### Skip Integrations and Routes
6. **Skip adding integrations** - we'll configure these manually
7. **Next**

### Configure Stages
8. **Stage name:** `$default`
9. **Auto-deploy:** Yes
10. **Next**

### Review and Create
11. **Review settings**
12. **Create**

---

## 5.3 Create HTTP Integrations

### Integration 1: Products Integration

1. **Go to your API → Integrations → Create integration**
2. **Integration type:** HTTP proxy integration
3. **Integration method:** GET
4. **Integration URI:** `http://<internal-alb-dns-name>/products`
   - Replace `<internal-alb-dns-name>` with your actual ALB DNS name
5. **VPC Link:** Select `ecommerce-vpc-link`
6. **Create integration**

### Integration 2: Proxy Integration for Other Routes

1. **Create integration**
2. **Integration type:** HTTP proxy integration
3. **Integration method:** ANY
4. **Integration URI:** `http://<internal-alb-dns-name>/{proxy}`
   - Replace `<internal-alb-dns-name>` with your actual ALB DNS name
5. **VPC Link:** Select `ecommerce-vpc-link`
6. **Create integration**

**Note:** 
- Products integration uses direct `/products` path
- Proxy integration uses `{proxy}` parameter to capture and forward the entire request path

---

## 5.4 Create JWT Authorizer

### Cognito JWT Authorizer Configuration

1. **Go to your API → Authorization → Authorizers → Create authorizer**
2. **Name:** `cognito-jwt-authorizer`
3. **Authorizer type:** JWT
4. **Identity source:** `$request.header.Authorization`
5. **Issuer URL:** `https://cognito-idp.<your-region>.amazonaws.com/<user-pool-id>`
   - Replace `<your-region>` and `<user-pool-id>` with your values
6. **Audience:** `<your-app-client-id>`
   - Use the App Client ID from Module 3
7. **Create authorizer**

---

## 5.5 Create API Routes

### Route 1: Public Products Route

1. **Go to your API → Routes → Create route**
2. **Method:** GET
3. **Resource path:** `/products`
4. **Integration:** Select the **Products Integration** created above
5. **Authorization:** None
6. **Create route**

### Route 2: Authenticated Proxy Route

1. **Create route**
2. **Method:** ANY
3. **Resource path:** `/{proxy+}`
4. **Integration:** Select the **Proxy Integration** created above
5. **Authorization:** JWT
6. **Authorizer:** Select `cognito-jwt-authorizer`
7. **Create route**

### Route 3: CORS Preflight Route

1. **Create route**
2. **Method:** OPTIONS
3. **Resource path:** `/{proxy+}`
4. **Integration:** Select the **Proxy Integration** created above
5. **Authorization:** None
6. **Create route**

**Note:** 
- `/products` is public (no authentication required)
- `/{proxy+}` requires JWT authentication for all other endpoints
- `OPTIONS /{proxy+}` handles CORS preflight requests without authentication

---

## 5.6 Configure CORS

### CORS Configuration

1. **Go to your API → CORS → Configure**
2. **Access-Control-Allow-Origin:** `*` (or specify your frontend domain)
3. **Access-Control-Allow-Headers:** 
   ```
   Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token
   ```
4. **Access-Control-Allow-Methods:** 
   ```
   GET,POST,PUT,DELETE,OPTIONS
   ```
5. **Save**

---

## 5.7 Test API Gateway

### Get API Gateway URL

1. **Go to your API → Stages → $default**
2. **Copy the Invoke URL** (e.g., `https://xxxxxxxxxx.execute-api.<region>.amazonaws.com`)

### Get JWT Token for Testing

Before testing authenticated endpoints, you need to get a JWT token from Cognito:

**Get JWT Token using AWS CLI:**
```bash
# Replace with your values from Module 3
USER_POOL_ID="<your-user-pool-id>"
CLIENT_ID="<your-app-client-id>"
USERNAME="<test-user-email>"
PASSWORD="<test-user-password>"

# Get JWT token
JWT_TOKEN=$(aws cognito-idp admin-initiate-auth \
  --user-pool-id $USER_POOL_ID \
  --client-id $CLIENT_ID \
  --auth-flow ADMIN_NO_SRP_AUTH \
  --auth-parameters USERNAME=$USERNAME,PASSWORD=$PASSWORD \
  --query 'AuthenticationResult.IdToken' \
  --output text)

echo "JWT Token: $JWT_TOKEN"
```

**Create Test User (if needed):**
```bash
# Create a test user
aws cognito-idp admin-create-user \
  --user-pool-id $USER_POOL_ID \
  --username testuser@example.com \
  --user-attributes Name=email,Value=testuser@example.com Name=name,Value="Test User" \
  --temporary-password "TempPass123!" \
  --message-action SUPPRESS

# Set permanent password
aws cognito-idp admin-set-user-password \
  --user-pool-id $USER_POOL_ID \
  --username testuser@example.com \
  --password "TestPass123!" \
  --permanent
```

### Test All Service Endpoints

**Test Public Products Endpoint (No Auth Required):**
```bash
curl https://xxxxxxxxxx.execute-api.<region>.amazonaws.com/products
```

**Test Authenticated Endpoints (JWT Required):**
```bash
# Use the JWT token obtained above
curl -H "Authorization: Bearer $JWT_TOKEN" https://xxxxxxxxxx.execute-api.<region>.amazonaws.com/cart

curl -H "Authorization: Bearer $JWT_TOKEN" https://xxxxxxxxxx.execute-api.<region>.amazonaws.com/users

curl -H "Authorization: Bearer $JWT_TOKEN" https://xxxxxxxxxx.execute-api.<region>.amazonaws.com/orders
```

**Test CORS Preflight (No Auth Required):**
```bash
curl -X OPTIONS https://xxxxxxxxxx.execute-api.<region>.amazonaws.com/cart \
  -H "Origin: http://localhost:3000" \
  -H "Access-Control-Request-Method: GET" \
  -H "Access-Control-Request-Headers: Authorization" \
  -v
```

**Test Without Token on Protected Endpoints (Should Return 401):**
```bash
curl https://xxxxxxxxxx.execute-api.<region>.amazonaws.com/cart
curl https://xxxxxxxxxx.execute-api.<region>.amazonaws.com/users
curl https://xxxxxxxxxx.execute-api.<region>.amazonaws.com/orders
# Expected: {"message":"Unauthorized"}
```

### Expected Response
Each endpoint should return a JSON response from the respective microservice when a valid JWT token is provided. If you get errors, verify:
- VPC Link status is "Available"
- Internal ALB is healthy and accessible
- ECS services are running and registered with target groups
- Security groups allow traffic flow
- **JWT token is valid and not expired**
- **Cognito User Pool ID and App Client ID are correct in authorizer**

### Troubleshooting

**401 Unauthorized:**
- Check JWT token is valid and not expired
- Verify Cognito User Pool ID in authorizer configuration
- Ensure App Client ID matches in authorizer audience

**403 Forbidden:**
- Check JWT token format (should be `Bearer <token>`)
- Verify token is from correct Cognito User Pool

**502 Bad Gateway:**
- Check VPC Link status
- Verify internal ALB DNS name in integration URI
- Ensure ALB target groups are healthy

**504 Gateway Timeout:**
- Check ECS service health
- Verify ALB listener rules are configured correctly
- Check security group rules

---

## 5.8 Update Parameter Store

### API Gateway URL Parameter

1. **Systems Manager Console → Parameter Store → Create parameter**
2. **Name:** `/ecommerce/dev/api-gateway-url`
3. **Type:** String
4. **Value:** `https://xxxxxxxxxx.execute-api.<region>.amazonaws.com`

This parameter can be used by the frontend application to know the API base URL.

## Architecture Benefits

1. **Mixed Authentication:** Public products endpoint, authenticated for other services
2. **CORS Support:** Dedicated OPTIONS route for preflight requests
3. **ALB Handles Logic:** Path-based routing managed by ALB (already configured)
4. **Secure Connection:** VPC Link ensures private communication
5. **Flexible Access:** Public product browsing, authenticated user actions
6. **Cost Effective:** Minimal API Gateway configuration reduces complexity

## Next Steps
Proceed to **[Module 6: Frontend Deployment](./module6-frontend-deployment.md)** to deploy the React application.
