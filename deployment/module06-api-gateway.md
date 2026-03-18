# Module 6: API Gatewaywith VPC Link

## Overview
Create an HTTP API Gateway that connects to the internal Application Load Balancer using VPC Link, providing a public endpoint to access all microservices.

## What We'll Build
- **5.1** VPC Link for secure connection to internal ALB
- **5.2** HTTP API Gateway with $default stage
- **5.3** Single HTTP proxy integration to internal ALB
- **5.4** Cognito JWT Authorizer for authentication
- **5.5** Three API routes: public products, authenticated proxy, and CORS
- **5.6** CORS configuration for frontend access
- **5.7** API endpoint testing with mixed authentication
- **5.8** Parameter Store configuration for API Gateway URL

## Architecture
```
Internet → API Gateway → VPC Link → Internal ALB → ECS Services
```

The API Gateway will have three specific routes:
- `GET /products` → Product Service (public, no auth)
- `ANY /{proxy+}` → All Services (authenticated, Cognito-authorizer required)
- `OPTIONS /{proxy+}` → CORS preflight (public, no auth)

---

## 5.1 Create VPC Link

### 5.1.1 Create Security Group for VPC Link

1. **VPC Console → Security Groups → Create security group**
2. **Name:** `ecommerce-vpclink-sg`
3. **Description:** "Security group for VPC Link to ALB"
4. **VPC:** Select `ecommerce-vpc`
5. **Inbound rules:**
   - Type: HTTP, Port: 80, Source: 0.0.0.0/0 (API Gateway traffic)
   - Type: HTTPS, Port: 443, Source: 0.0.0.0/0 (API Gateway traffic)
6. **Outbound rules:** All traffic (default)
7. **Create security group**

### 5.1.2 VPC Link Configuration

1. **API Gateway Console → VPC Links → Create VPC Link**
2. **VPC Link version:** VPC Link for HTTP APIs (v2)
3. **Name:** `ecommerce-vpc-link`
4. **Description:** "VPC Link for ecommerce internal ALB"
5. **VPC:** Select `ecommerce-vpc`
6. **Subnets:** Select both private ECS subnets:
   - `ecommerce-private-ecs-1`
   - `ecommerce-private-ecs-2`
7. **Security groups:** Select `ecommerce-vpclink-sg`
8. **Create VPC Link**

**Note:** VPC Link creation takes 5-10 minutes. Wait for status to become "Available" before proceeding.

---

## 5.2 Create HTTP API Gateway

### API Gateway Configuration

1. **API Gateway Console → APIs → Create API**
2. **Choose:** HTTP API → Build
3. **API name:** `ecommerce-api`
4. **Description:** "eCommerce HTTP API"
5. **Next**
6. **Skip adding integrations** - we'll configure these manually
7. **Create**

---

## 5.3 Create HTTP Integration

### ALB Integration over VPCLink (VPC Private Resource integration)

Create one integration that will be used by all routes:

1. **Go to your API → Develop → Integrations → Manage integrations → Create**
2. **Integration type:** Private resource
3. **Target service:** ALB/NLB
4. **Load balancer:** Select `ecommerce-internal-alb`
5. **Listener:** HTTP:80
6. **VPC Link:** Select `ecommerce-vpc-link`
7. **Create integration**

**Note:** This single integration connects to your ALB and will be reused by all three routes. The ALB handles path-based routing to the appropriate microservices.

---

## 5.4 Create Cognito JWT Authorizer

### Cognito JWT Authorizer Configuration

1. **Go to your API → Authorization → Authorizers → Create authorizer**
2. **Name:** `cognito-jwt-authorizer`
3. **Authorizer type:** JWT
4. **Identity source:** `$request.header.Authorization`
5. **Issuer URL:** `https://cognito-idp.<your-region>.amazonaws.com/<user-pool-id>`
   - Replace `<your-region>` and `<user-pool-id>` with your values or get this URL from Cognito -> User Pool -> App Client -> Quick Setup guide -> authority
6. **Audience:** `<your-app-client-id>`
   - Use the App Client ID from Module 3
7. **Create authorizer**

---

## 5.5 Create API Routes

### Route 1: Public Products Route

1. **Go to your API → Routes → Create route**
2. **Method:** GET
3. **Resource path:** `/products`
4. **Integration:** Select the **ALB Integration** created above
5. **Authorization:** None
6. **Create route**

### Route 2: Authenticated Proxy Route

1. **Create route**
2. **Method:** ANY
3. **Resource path:** `/{proxy+}`
4. **Integration:** Select the **ALB Integration** created above
5. **Authorization:** JWT
6. **Authorizer:** Select `cognito-jwt-authorizer`
7. **Create route**

### Route 3: CORS Preflight Route

1. **Create route**
2. **Method:** OPTIONS
3. **Resource path:** `/{proxy+}`
4. **Integration:** Select the **ALB Integration** created above
5. **Authorization:** None
6. **Create route**

**Note:** 
- All three routes use the same ALB integration
- `/products` is public (no authentication required)
- `/{proxy+}` requires JWT authentication for all other endpoints
- `OPTIONS /{proxy+}` handles CORS preflight requests without authentication

---

## 5.6 Configure CORS

### CORS Configuration

1. **Go to your API → CORS → Configure**
2. **Access-Control-Allow-Origin:** `*` (or specify your frontend domain)
3. **Access-Control-Allow-Headers:** `*` (allows all headers - recommended for development)
4. **Access-Control-Allow-Methods:** 
   ```
   GET,POST,PUT,DELETE,OPTIONS
   ```
5. **Save**

**Note:** Using `*` for Access-Control-Allow-Headers prevents CORS preflight issues with custom headers like Authorization tokens.

---

## 5.7 Test API Gateway

### Get API Gateway URL

1. **Go to your API → Stages → $default**
2. **Copy the Invoke URL** (e.g., `https://xxxxxxxxxx.execute-api.<region>.amazonaws.com`)
3. This parameter is used by the frontend application to know the API base URL to access backend services. We will configure it in the next module.

### Test All Service Endpoints

**Test Public Products Endpoint (No Auth Required):**
```bash
curl https://xxxxxxxxxx.execute-api.<region>.amazonaws.com/products
```

**Test Authorized Endpoints (Should Return 401):**
```bash
curl https://xxxxxxxxxx.execute-api.<region>.amazonaws.com/cart
curl https://xxxxxxxxxx.execute-api.<region>.amazonaws.com/users
curl https://xxxxxxxxxx.execute-api.<region>.amazonaws.com/orders
# Expected: {"message":"Unauthorized"}
```

### Troubleshooting

**CORS Errors:**
- If you see "Access-Control-Allow-Origin" errors, ensure CORS is configured with `Access-Control-Allow-Headers: *`
- Verify OPTIONS routes are created for preflight requests
- Check that API Gateway CORS settings match your frontend domain

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

**DynamoDB ValidationException:**
- If cart service fails with "key element does not match schema", ensure cart table has only `user_id` as partition key (no sort key)

---

## We have configured:

1. **Authentication:** Public products endpoint, authenticated for other services
2. **CORS Support:** Dedicated OPTIONS route for preflight requests
3. **Secure Connection:** VPC Link ensures private communication between API gateway and ALB.
4. **Flexible Access:** Public product browsing, authenticated user actions

## Next Steps
Proceed to **[Module 7: Frontend-Backend Integration](./module07-frontend-backend-integration.md)** to configure, build, and deploy the React application.
