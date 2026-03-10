# Module 5: API Gateway with VPC Link

## Overview
Create an API Gateway HTTP API with VPC Link integration to securely connect to the internal Application Load Balancer, providing a unified entry point for all microservices with Cognito authentication.

## What We'll Build
1. **VPC Link** - Secure connection from API Gateway to internal ALB
2. **HTTP API** - Modern API Gateway with better performance and lower cost
3. **Cognito JWT Authorizer** - Authentication for protected routes
4. **API Routes** - Public and authenticated endpoints
5. **HTTP Integrations** - Route traffic to internal ALB via VPC Link
6. **CORS Configuration** - Enable cross-origin requests for frontend

## Architecture
```
Internet → API Gateway (HTTP API) → VPC Link → Internal ALB → ECS Services
                ↓
         Cognito JWT Authorizer
                ↓
Routes:
├── GET /products (public) → Internal ALB/products
├── GET /cart/* (auth) → Internal ALB/cart/*
├── POST /orders/* (auth) → Internal ALB/orders/*
└── GET /users/* (auth) → Internal ALB/users/*
```

## Step 1: Create VPC Link

### AWS Console
1. **API Gateway Console → VPC Links → Create VPC Link**
2. **Name:** `ecommerce-vpc-link`
3. **Target type:** Application Load Balancer
4. **VPC:** ecommerce-vpc
5. **Target:** Select `ecommerce-internal-alb`
6. **Create VPC Link**

**Note:** VPC Link creation takes 5-10 minutes. Wait for status to become "Available".

### AWS CLI
```bash
INTERNAL_ALB_ARN=$(grep "INTERNAL_ALB_ARN=" deployment/vpc-resources.txt | cut -d'=' -f2)

VPC_LINK_ID=$(aws apigatewayv2 create-vpc-link \
  --name ecommerce-vpc-link \
  --subnet-ids $(grep "PRIVATE_SUBNET_1=" deployment/vpc-resources.txt | cut -d'=' -f2) $(grep "PRIVATE_SUBNET_2=" deployment/vpc-resources.txt | cut -d'=' -f2) \
  --query 'VpcLinkId' --output text --region ap-south-1)

echo "VPC_LINK_ID=$VPC_LINK_ID" >> deployment/vpc-resources.txt

# Wait for VPC Link to be available
echo "Waiting for VPC Link to be available..."
aws apigatewayv2 get-vpc-link --vpc-link-id $VPC_LINK_ID --region ap-south-1 --query 'VpcLinkStatus' --output text
```

## Step 2: Create HTTP API

### AWS Console
1. **API Gateway Console → APIs → Create API**
2. **Choose:** HTTP API → Build
3. **API name:** `ecommerce-api`
4. **Description:** `eCommerce microservices API`
5. **Create API**

### AWS CLI
```bash
API_ID=$(aws apigatewayv2 create-api \
  --name ecommerce-api \
  --protocol-type HTTP \
  --description "eCommerce microservices API" \
  --cors-configuration AllowOrigins="*",AllowMethods="*",AllowHeaders="*" \
  --query 'ApiId' --output text --region ap-south-1)

API_ENDPOINT=$(aws apigatewayv2 get-api \
  --api-id $API_ID \
  --query 'ApiEndpoint' --output text --region ap-south-1)

echo "API_ID=$API_ID" >> deployment/vpc-resources.txt
echo "API_ENDPOINT=$API_ENDPOINT" >> deployment/vpc-resources.txt
echo "API Gateway Endpoint: $API_ENDPOINT"
```

## Step 3: Create Cognito JWT Authorizer

### AWS Console
1. **API Gateway Console → APIs → ecommerce-api → Authorization → Authorizers**
2. **Create authorizer**
3. **Name:** `cognito-authorizer`
4. **Authorizer type:** JWT
5. **Identity source:** `$request.header.Authorization`
6. **Issuer URL:** `https://cognito-idp.ap-south-1.amazonaws.com/<user-pool-id>`
7. **Audience:** `<cognito-app-client-id>`
8. **Create authorizer**

### AWS CLI
```bash
USER_POOL_ID=$(grep "USER_POOL_ID=" deployment/vpc-resources.txt | cut -d'=' -f2)
APP_CLIENT_ID=$(grep "APP_CLIENT_ID=" deployment/vpc-resources.txt | cut -d'=' -f2)

AUTHORIZER_ID=$(aws apigatewayv2 create-authorizer \
  --api-id $API_ID \
  --authorizer-type JWT \
  --name cognito-authorizer \
  --identity-sources '$request.header.Authorization' \
  --jwt-configuration Audience="$APP_CLIENT_ID",Issuer="https://cognito-idp.ap-south-1.amazonaws.com/$USER_POOL_ID" \
  --query 'AuthorizerId' --output text --region ap-south-1)

echo "AUTHORIZER_ID=$AUTHORIZER_ID" >> deployment/vpc-resources.txt
```

## Step 4: Create HTTP Integration

### AWS Console
1. **API Gateway Console → APIs → ecommerce-api → Integrations → Create integration**
2. **Integration type:** HTTP
3. **Integration method:** ANY
4. **Integration URI:** `http://ecommerce-internal-alb-dns/{proxy}`
5. **Connection type:** VPC Link
6. **VPC Link:** Select `ecommerce-vpc-link`
7. **Create integration**

### AWS CLI
```bash
INTERNAL_ALB_DNS=$(grep "INTERNAL_ALB_DNS=" deployment/vpc-resources.txt | cut -d'=' -f2)

INTEGRATION_ID=$(aws apigatewayv2 create-integration \
  --api-id $API_ID \
  --integration-type HTTP_PROXY \
  --integration-method ANY \
  --integration-uri "http://$INTERNAL_ALB_DNS/{proxy}" \
  --connection-type VPC_LINK \
  --connection-id $VPC_LINK_ID \
  --payload-format-version "1.0" \
  --query 'IntegrationId' --output text --region ap-south-1)

echo "INTEGRATION_ID=$INTEGRATION_ID" >> deployment/vpc-resources.txt
```

## Step 5: Create API Routes

### AWS Console

**Public Route (Products):**
1. **Routes → Create route**
2. **Method:** GET
3. **Resource path:** `/products`
4. **Integration:** Select the HTTP integration
5. **Authorization:** None
6. **Create route**

**Authenticated Routes:**
1. **Create route for each:**
   - `ANY /{proxy+}` (catch-all for authenticated routes)
   - Method: ANY
   - Resource path: `/{proxy+}`
   - Integration: HTTP integration
   - Authorization: cognito-authorizer
   - Create route

### AWS CLI
```bash
# Create public products route
aws apigatewayv2 create-route \
  --api-id $API_ID \
  --route-key "GET /products" \
  --target "integrations/$INTEGRATION_ID" \
  --region ap-south-1

# Create catch-all authenticated route
aws apigatewayv2 create-route \
  --api-id $API_ID \
  --route-key "ANY /{proxy+}" \
  --target "integrations/$INTEGRATION_ID" \
  --authorization-type JWT \
  --authorizer-id $AUTHORIZER_ID \
  --region ap-south-1

# Create OPTIONS route for CORS preflight
aws apigatewayv2 create-route \
  --api-id $API_ID \
  --route-key "OPTIONS /{proxy+}" \
  --target "integrations/$INTEGRATION_ID" \
  --region ap-south-1
```

## Step 6: Deploy API

### AWS Console
1. **API Gateway Console → APIs → ecommerce-api → Deploy**
2. **Stage name:** `$default` (auto-deployment)
3. **Deploy**

### AWS CLI
```bash
# API Gateway HTTP APIs auto-deploy to $default stage
echo "API deployed automatically to \$default stage"
echo "API Gateway URL: $API_ENDPOINT"
```

## Step 7: Update CORS Configuration

### AWS Console
1. **API Gateway Console → APIs → ecommerce-api → CORS**
2. **Configure CORS:**
   - Access-Control-Allow-Origin: `*`
   - Access-Control-Allow-Headers: `*`
   - Access-Control-Allow-Methods: `*`
   - Access-Control-Max-Age: `86400`
3. **Save**

### AWS CLI
```bash
aws apigatewayv2 update-api \
  --api-id $API_ID \
  --cors-configuration AllowOrigins="*",AllowMethods="*",AllowHeaders="*",MaxAge=86400 \
  --region ap-south-1
```

## Step 8: Verification

### Test Public Endpoints
```bash
API_ENDPOINT=$(grep "API_ENDPOINT=" deployment/vpc-resources.txt | cut -d'=' -f2)

# Test public products endpoint
curl "$API_ENDPOINT/products"

# Test health endpoints (should work without auth)
curl "$API_ENDPOINT/users/health"
curl "$API_ENDPOINT/cart/health"
curl "$API_ENDPOINT/orders/health"
```

### Test Authenticated Endpoints
```bash
# These should return 401 Unauthorized without proper JWT token
curl "$API_ENDPOINT/users/profile"
curl "$API_ENDPOINT/cart"
curl "$API_ENDPOINT/orders"

# Test with invalid token (should return 401)
curl -H "Authorization: Bearer invalid-token" "$API_ENDPOINT/users/profile"
```

### Test CORS
```bash
# Test CORS preflight request
curl -X OPTIONS "$API_ENDPOINT/products" \
  -H "Origin: http://localhost:3000" \
  -H "Access-Control-Request-Method: GET" \
  -H "Access-Control-Request-Headers: Content-Type" \
  -v
```

### Verify VPC Link Status
```bash
aws apigatewayv2 get-vpc-link \
  --vpc-link-id $VPC_LINK_ID \
  --region ap-south-1 \
  --query '{Name:Name,Status:VpcLinkStatus,StatusMessage:VpcLinkStatusMessage}'
```

### Check API Gateway Logs
```bash
# Enable logging (optional)
aws apigatewayv2 update-stage \
  --api-id $API_ID \
  --stage-name '$default' \
  --access-log-settings DestinationArn="arn:aws:logs:ap-south-1:$(aws sts get-caller-identity --query Account --output text):log-group:/aws/apigateway/ecommerce-api",Format='$requestId $ip $requestTime $httpMethod $resourcePath $status $error.message $error.messageString' \
  --region ap-south-1
```

## Current API Routes

Based on the deployed configuration, the API Gateway has these routes:

| Method | Path | Auth Required | Target Service |
|--------|------|---------------|----------------|
| `GET` | `/products` | No | product-service |
| `ANY` | `/{proxy+}` | Yes (JWT) | All services via ALB |
| `OPTIONS` | `/{proxy+}` | No | CORS preflight |

## Testing with Frontend

Update your frontend configuration to use the API Gateway endpoint:

```javascript
// In your React app's config
const API_BASE_URL = 'https://your-api-id.execute-api.ap-south-1.amazonaws.com';

// Example API calls
const getProducts = () => fetch(`${API_BASE_URL}/products`);
const getUserProfile = (token) => fetch(`${API_BASE_URL}/users/profile`, {
  headers: { 'Authorization': `Bearer ${token}` }
});
```

## Security Benefits

1. **Network Isolation:** Internal ALB not exposed to internet
2. **VPC Link:** Secure connection between API Gateway and ALB
3. **JWT Authentication:** Cognito-based authentication for protected routes
4. **Rate Limiting:** Built-in API Gateway throttling
5. **WAF Integration:** Can add AWS WAF for additional protection

## Cost Optimization

- **HTTP API:** ~60% cheaper than REST API
- **VPC Link:** $0.025/hour (~$18/month)
- **API Gateway:** $1.00 per million requests
- **Data Transfer:** $0.09/GB for VPC Link data transfer

## Next Steps
- Module 6: Configure event-driven architecture with SNS/SQS
- The API Gateway endpoint will be used with custom domain in Module 8
**Note:** Cleanup steps have been removed from individual modules. A dedicated cleanup module will be provided at the end of the tutorial.
