# Module 5: API Gateway

## Overview
Create an API Gateway to provide a unified entry point for all microservices with Cognito authentication.

## Architecture
```
API Gateway (HTTP API)
├── Cognito Authorizer
├── HTTP Integration → Public ALB
└── Routes:
    ├── GET /products → ALB/api/products
    ├── GET /cart → ALB/api/cart (authenticated)
    ├── POST /orders → ALB/api/orders (authenticated)
    └── GET /users/profile → ALB/api/users/profile (authenticated)
```

## Why API Gateway?
- Single entry point for all APIs
- Built-in authentication with Cognito
- Request/response transformation
- Rate limiting and throttling
- API versioning
- Monitoring and logging
- Custom domain support

## Resources to Create

### 1. HTTP API
- Name: ecommerce-api
- Protocol: HTTP
- CORS: Enabled
- Integration: HTTP proxy to ALB

### 2. Cognito Authorizer
- Type: JWT
- Identity source: $request.header.Authorization
- Audience: Cognito App Client ID

### 3. Routes
- Public routes (no auth): GET /products, GET /products/{id}
- Authenticated routes: /cart/*, /orders/*, /users/*

## Console Steps

### Step 1: Get ALB DNS Name

1. Go to EC2 Console → Load Balancers
2. Select `ecommerce-alb`
3. Copy the DNS name (e.g., `ecommerce-alb-123456789.ap-south-1.elb.amazonaws.com`)
4. Save this - you'll need it for API Gateway integration

### Step 2: Create HTTP API

1. API Gateway Console → APIs → Create API
2. Choose: HTTP API → Build
3. Integrations:
   - Add integration: HTTP
   - Integration type: HTTP proxy
   - URL endpoint: `http://<alb-dns-name>` (paste your ALB DNS)
   - Method: ANY
4. API name: `ecommerce-api`
5. Next

**Configure routes:**
6. Route: `/{proxy+}` (catch-all route)
7. Method: ANY
8. Next

**Configure stages:**
9. Stage name: $default (auto-deploy)
10. Next

11. Review and Create

### Step 3: Configure CORS

1. Go to your API → CORS
2. Configure:
   - Access-Control-Allow-Origin: * (or specific domain)
   - Access-Control-Allow-Headers: content-type, x-user-id, authorization
   - Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
3. Save

### Step 4: Create Cognito Authorizer

1. API → Authorizers → Create
2. Authorizer type: JWT
3. Name: `cognito-authorizer`
4. Identity source: `$request.header.Authorization`
5. Issuer URL: `https://cognito-idp.ap-south-1.amazonaws.com/<user-pool-id>`
6. Audience: `<app-client-id>` (from Cognito)
7. Create

### Step 5: Update Routes with Authorization

The catch-all route `/{proxy+}` forwards all requests to ALB. Now we need to add authorization to specific routes:

1. API → Routes
2. Delete the catch-all route `ANY /{proxy+}`
3. Create specific routes:

**Public Routes (no auth):**

- `GET /api/products`
- `GET /api/products/{id}`

**Authenticated Routes (add authorizer):**

For each route below, select `cognito-authorizer`:
- `GET /api/cart`
- `POST /api/cart/items`
- `DELETE /api/cart/items/{productId}`
- `POST /api/orders`
- `GET /api/orders`
- `GET /api/users/profile`
- `POST /api/users/profile`

**Note:** All routes use the same HTTP integration to ALB.

### Step 6: Note API Endpoint
### Step 6: Note API Endpoint

1. Go to API → Stages → $default
2. Copy the Invoke URL (e.g., `https://xxxxxxxxxx.execute-api.ap-south-1.amazonaws.com`)
3. Save this - you'll use it in your frontend

## Testing

### Test Public Endpoint (No Auth)
```bash
API_ENDPOINT="https://<api-id>.execute-api.ap-south-1.amazonaws.com"
curl $API_ENDPOINT/api/products
```

### Test Authenticated Endpoint
```bash
# First, get a token from Cognito (use Hosted UI or SDK)
TOKEN="<your-jwt-token>"

curl -H "Authorization: Bearer $TOKEN" \
  $API_ENDPOINT/api/cart
```

### Test from Frontend
Update your React app to use the new API Gateway endpoint and test authentication flow.

## Update Frontend Configuration

Update `frontend/react-app/.env`:
```
REACT_APP_API_URL=https://xxxxxxxxxx.execute-api.ap-south-1.amazonaws.com
```

Or update `src/api.js`:
```javascript
const API_BASE_URL = 'https://xxxxxxxxxx.execute-api.ap-south-1.amazonaws.com';
```

## Verification

### Check API Gateway
1. Go to API Gateway Console → APIs → ecommerce-api
2. Check Routes tab - should see all routes
3. Check Authorizers tab - should see cognito-authorizer
4. Check Integrations tab - should see HTTP integration to ALB

### Test Each Route
```bash
# Public route (should work)
curl $API_ENDPOINT/api/products

# Protected route without token (should return 401)
curl $API_ENDPOINT/api/cart

# Protected route with token (should work)
curl -H "Authorization: Bearer $TOKEN" $API_ENDPOINT/api/cart
```

## Monitoring

### Enable CloudWatch Logs
1. API Gateway Console → Your API → Stages → $default
2. Logs and tracing:
   - CloudWatch Logs: Enable
   - Log level: INFO
   - Log full requests/responses: Yes (for debugging)
3. Save

### View Logs
```bash
aws logs tail /aws/apigateway/ecommerce-api --follow --region ap-south-1
```

## Cost Considerations
- API Gateway HTTP API: $1.00 per million requests
- Data transfer: $0.09/GB (first 10TB)
- For low traffic: ~$1-5/month

## Cleanup Commands
```bash
# Delete API
aws apigatewayv2 delete-api \
  --api-id $API_ID \
  --region ap-south-1
```

## Next Steps
After completing this module:
- ✅ API Gateway providing unified API endpoint
- ✅ Cognito authentication integrated
- ✅ HTTP integration to public ALB
- ✅ CORS configured for frontend
- Ready for Module 6: Event-Driven Architecture (SNS/SQS)
