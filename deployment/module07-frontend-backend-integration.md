# Module 7: Frontend-Backend Integration

## Overview
Now that the API Gateway is deployed, update the React application with the API Gateway URL, rebuild, and redeploy to S3. This completes the frontend integration and makes all features fully functional.

## What We'll Do
- **7.1** Update `aws-config.js` with the API Gateway URL
- **7.2** Rebuild and redeploy to S3
- **7.3** Invalidate CloudFront cache
- **7.4** Test the fully integrated application

## Prerequisites
You will need the following value from Module 6:

| Value | Where to Find |
|-------|--------------|
| API Gateway URL | Module 6 → API Gateway Console → Stages → $default → Invoke URL |

---

## 7.1 Update AWS Configuration

1. **Navigate to frontend directory:**
```bash
cd frontend/react-app
```

2. **Edit `src/aws-config.js`** — update only the `baseUrl` field:
```javascript
const awsConfig = {
  Auth: {
    Cognito: {
      userPoolId: '<COGNITO_USER_POOL_ID>',       // Already set in Module 3
      userPoolClientId: '<COGNITO_CLIENT_ID>',    // Already set in Module 3
      loginWith: {
        email: true,
      },
    }
  },
  API: {
    baseUrl: '<API_GATEWAY_URL>'  // e.g., https://xxxxxxxxxx.execute-api.us-east-1.amazonaws.com
  }
};

export default awsConfig;
```

---

## 7.2 Rebuild and Redeploy to S3

```bash
npm run build
aws s3 sync build/ s3://<your-frontend-bucket-name> --delete
```

---

## 7.3 Invalidate CloudFront Cache

```bash
aws cloudfront create-invalidation \
  --distribution-id <your-cloudfront-distribution-id> \
  --paths "/*"
```

Invalidation typically completes within 1-2 minutes.

---

## 7.4 Test the Fully Integrated Application

Open your CloudFront URL in a browser:
```
https://<your-cloudfront-domain>
```

**Full test checklist:**
- ✅ Login / signup (Cognito)
- ✅ Product listing loads from backend
- ✅ Add/remove items from cart
- ✅ Place a test order
- ✅ View order history

### Troubleshooting

**Products still not loading:**
- Confirm CloudFront invalidation has completed
- Verify the API Gateway URL in `aws-config.js` has no trailing slash
- Check API Gateway CORS configuration (Module 6)
- Ensure ECS services are healthy (Module 5)

**Authentication errors:**
- Verify Cognito User Pool ID and Client ID are unchanged from Module 3

**502 / 504 errors:**
- Check ECS service health in the ECS Console
- Review CloudWatch logs for the failing service

## Next Steps
Proceed to **[Module 8: Notification](./module08-notification.md)** to set up SNS and SQS for order notifications.
