# Module 6: API Gateway

## Overview
Create an HTTP API Gateway that connects to the internal Application Load Balancer, providing a public endpoint to access all microservices.

## In this module
- Create a VPC Link for API Gateway to connect privately to the internal ALB
- Create HTTP API Gateway
- Create HTTP proxy integration to internal ALB (VPC Resource) via VPCLink
- Create Cognito JWT Authorizer for authentication
- Create API routes
- API CORS configuration for frontend access
- API endpoint testing

## Architecture
<img width="800" height="300" alt="image" src="https://github.com/user-attachments/assets/2c4d0409-7b84-4aba-b62a-780de8edaaf3" />

The API Gateway will have three specific routes:
- `GET /products` → Product Service (public, no auth)
- `ANY /{proxy+}` → All Services (authenticated, Cognito-authorizer required)
- `OPTIONS /{proxy+}` → CORS preflight (public, no auth)

## 6.1 Create VPC Link

### 6.1.1 Create Security Group for VPC Link

1. **VPC Console → Security Groups → Create security group**
2. **Name:** `ecommerce-vpclink-sg`
3. **Description:** "Security group for VPC Link to ALB"
4. **VPC:** Select `ecommerce-vpc`
5. **Inbound rules:**
   - Type: HTTP, Port: 80, Source: 0.0.0.0/0 (API Gateway traffic)
   - Type: HTTPS, Port: 443, Source: 0.0.0.0/0 (API Gateway traffic)
6. **Outbound rules:** All traffic (default)
7. **Create security group**

<details>
<summary><strong>CLI equivalent</strong></summary>

```bash
VPCLINK_SG=$(aws ec2 create-security-group \
  --group-name ecommerce-vpclink-sg \
  --description "Security group for VPC Link to ALB" \
  --vpc-id $VPC_ID \
  --query 'GroupId' --output text)

aws ec2 authorize-security-group-ingress \
  --group-id $VPCLINK_SG \
  --ip-permissions \
    IpProtocol=tcp,FromPort=80,ToPort=80,IpRanges=[{CidrIp=0.0.0.0/0}] \
    IpProtocol=tcp,FromPort=443,ToPort=443,IpRanges=[{CidrIp=0.0.0.0/0}]

echo "VPCLINK_SG=$VPCLINK_SG"
```

</details>

### 6.1.2 VPC Link Configuration

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

<details>
<summary><strong>CLI equivalent</strong></summary>

```bash
VPC_LINK_ID=$(aws apigatewayv2 create-vpc-link \
  --name ecommerce-vpc-link \
  --subnet-ids $ECS_SUBNET_1 $ECS_SUBNET_2 \
  --security-group-ids $VPCLINK_SG \
  --query 'VpcLinkId' --output text)

echo "VPC_LINK_ID=$VPC_LINK_ID"
# Wait ~5-10 minutes for status to become AVAILABLE before proceeding
```

</details>

## 6.2 Create HTTP API Gateway

### API Gateway Configuration

1. **API Gateway Console → APIs → Create API**
2. **Choose:** HTTP API → Build
3. **API name:** `ecommerce-api`
4. **Description:** "eCommerce HTTP API"
5. **Next**
6. **Skip adding integrations** - we'll configure these manually
7. **Create**
8. **Go to your API → Stages → Create stage**
   - Stage name: `$default`
   - Enable Auto-deploy
   - **Create**

<details>
<summary><strong>CLI equivalent</strong></summary>

```bash
API_ID=$(aws apigatewayv2 create-api \
  --name ecommerce-api \
  --protocol-type HTTP \
  --query 'ApiId' --output text)

# Create $default stage with auto-deploy
aws apigatewayv2 create-stage \
  --api-id $API_ID \
  --stage-name '$default' \
  --auto-deploy > /dev/null

echo "API_ID=$API_ID"
```

</details>



## 6.3 Create HTTP Integration

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

<details>
<summary><strong>CLI equivalent</strong></summary>

```bash
# Retrieve API_ID, VPC_LINK_ID and ALB LISTENER_ARN dynamically
API_ID=$(aws apigatewayv2 get-apis \
  --query 'Items[?Name==`ecommerce-api`].ApiId' --output text)

VPC_LINK_ID=$(aws apigatewayv2 get-vpc-links \
  --query 'Items[?Name==`ecommerce-vpc-link`].VpcLinkId' --output text)

ALB_ARN=$(aws elbv2 describe-load-balancers \
  --names ecommerce-internal-alb \
  --query 'LoadBalancers[0].LoadBalancerArn' --output text)

LISTENER_ARN=$(aws elbv2 describe-listeners \
  --load-balancer-arn $ALB_ARN \
  --query 'Listeners[?Port==`80`].ListenerArn' --output text)

echo "API_ID=$API_ID"
echo "VPC_LINK_ID=$VPC_LINK_ID"
echo "LISTENER_ARN=$LISTENER_ARN"

INTEGRATION_ID=$(aws apigatewayv2 create-integration \
  --api-id $API_ID \
  --integration-type HTTP_PROXY \
  --integration-method ANY \
  --integration-uri $LISTENER_ARN \
  --connection-type VPC_LINK \
  --connection-id $VPC_LINK_ID \
  --payload-format-version 1.0 \
  --query 'IntegrationId' --output text)

echo "INTEGRATION_ID=$INTEGRATION_ID"
```

</details>



## 6.4 Create Cognito JWT Authorizer

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

<details>
<summary><strong>CLI equivalent</strong></summary>

```bash
# Retrieve all required variables dynamically
API_ID=$(aws apigatewayv2 get-apis \
  --query 'Items[?Name==`ecommerce-api`].ApiId' --output text)

REGION=$(aws configure get region)

USER_POOL_ID=$(aws cognito-idp list-user-pools --max-results 60 \
  --query 'UserPools[?Name==`ecommerce-app`].Id' --output text)

CLIENT_ID=$(aws cognito-idp list-user-pool-clients \
  --user-pool-id $USER_POOL_ID \
  --query 'UserPoolClients[0].ClientId' --output text)

echo "API_ID=$API_ID"
echo "USER_POOL_ID=$USER_POOL_ID"
echo "CLIENT_ID=$CLIENT_ID"

AUTHORIZER_ID=$(aws apigatewayv2 create-authorizer \
  --api-id $API_ID \
  --name cognito-jwt-authorizer \
  --authorizer-type JWT \
  --identity-source '$request.header.Authorization' \
  --jwt-configuration \
    Issuer=https://cognito-idp.${REGION}.amazonaws.com/${USER_POOL_ID},Audience=$CLIENT_ID \
  --query 'AuthorizerId' --output text)

echo "AUTHORIZER_ID=$AUTHORIZER_ID"
```

</details>



## 6.5 Create API Routes

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

<details>
<summary><strong>CLI equivalent</strong></summary>

```bash
# Retrieve required variables dynamically
API_ID=$(aws apigatewayv2 get-apis \
  --query 'Items[?Name==`ecommerce-api`].ApiId' --output text)

INTEGRATION_ID=$(aws apigatewayv2 get-integrations \
  --api-id $API_ID \
  --query 'Items[0].IntegrationId' --output text)

AUTHORIZER_ID=$(aws apigatewayv2 get-authorizers \
  --api-id $API_ID \
  --query 'Items[?Name==`cognito-jwt-authorizer`].AuthorizerId' --output text)

echo "API_ID=$API_ID"
echo "INTEGRATION_ID=$INTEGRATION_ID"
echo "AUTHORIZER_ID=$AUTHORIZER_ID"

INTEG_TARGET=integrations/$INTEGRATION_ID

# Route 1: Public products
aws apigatewayv2 create-route \
  --api-id $API_ID \
  --route-key "GET /products" \
  --target $INTEG_TARGET > /dev/null && echo "Route created: GET /products"

# Route 2: Authenticated proxy
aws apigatewayv2 create-route \
  --api-id $API_ID \
  --route-key "ANY /{proxy+}" \
  --target $INTEG_TARGET \
  --authorization-type JWT \
  --authorizer-id $AUTHORIZER_ID > /dev/null && echo "Route created: ANY /{proxy+}"

# Route 3: CORS preflight (no auth)
aws apigatewayv2 create-route \
  --api-id $API_ID \
  --route-key "OPTIONS /{proxy+}" \
  --target $INTEG_TARGET > /dev/null && echo "Route created: OPTIONS /{proxy+}"
```

</details>


## 6.6 Configure CORS

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

<details>
<summary><strong>CLI equivalent</strong></summary>

```bash
API_ID=$(aws apigatewayv2 get-apis \
  --query 'Items[?Name==`ecommerce-api`].ApiId' --output text)

aws apigatewayv2 update-api \
  --api-id $API_ID \
  --cors-configuration \
    AllowOrigins='["*"]',AllowHeaders='["*"]',AllowMethods='["GET","POST","PUT","DELETE","OPTIONS"]' > /dev/null

echo "CORS configured for API: $API_ID"
```

</details>


## 6.7 Test API Gateway

### Get API Gateway URL

1. **Go to your API → Stages → $default**
2. **Copy the Invoke URL** (e.g., `https://xxxxxxxxxx.execute-api.<region>.amazonaws.com`)

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

<details>
<summary><strong>CLI equivalent</strong></summary>

```bash
# Get API Gateway URL
API_ID=$(aws apigatewayv2 get-apis \
  --query 'Items[?Name==`ecommerce-api`].ApiId' --output text)

API_URL=$(aws apigatewayv2 get-api \
  --api-id $API_ID \
  --query 'ApiEndpoint' --output text)

echo "API_URL=$API_URL"

# Test public products endpoint (expect 200 with product list)
echo "Testing /products (public)..."
curl -s $API_URL/products | head -c 200

# Test authenticated endpoints (expect 401 Unauthorized)
echo ""
echo "Testing /cart (should return 401)..."
curl -s $API_URL/cart

echo ""
echo "Testing /users (should return 401)..."
curl -s $API_URL/users

echo ""
echo "Testing /orders (should return 401)..."
curl -s $API_URL/orders
```

</details>

### Troubleshooting

**CORS Errors:**
- If you see "Access-Control-Allow-Origin" errors, ensure CORS is configured with `Access-Control-Allow-Headers: *`
- Verify OPTIONS routes are created for preflight requests

**401 Unauthorized:**
- Verify Cognito User Pool ID in authorizer configuration
- Ensure App Client ID matches in authorizer audience

**502 Bad Gateway:**
- Check VPC Link status
- Verify internal ALB DNS name in integration URI
- Ensure ALB target groups are healthy

**504 Gateway Timeout:**
- Check ECS service health
- Verify ALB listener rules are configured correctly
- Check VPCLink Security group (should allow HTTP/HTTPS from 0.0.0.0/0) and ALB Security group (should allow HTTP from VPC CIDR)
    

## We have configured:

1. **Authentication:** Public products endpoint, authenticated for other services
2. **CORS Support:** Dedicated OPTIONS route for preflight requests
3. **Secure Connection:** VPC Link ensures private communication between API gateway and ALB.
4. **Flexible Access:** Public product browsing, authenticated user actions

## Next Steps
Proceed to **[Module 7: Frontend-Backend Integration](./module07-frontend-backend-integration.md)**
