# Module 7: Frontend-Backend Integration

## Overview
Now that the API Gateway is deployed, update the React application with the API Gateway URL, rebuild, and redeploy to S3. This completes the frontend integration and makes all features fully functional.

## In this module
- Update frontend with the API Gateway URL
- Rebuild and redeploy frontend to S3
- Invalidate CloudFront cache
- Test the fully integrated application

## 7.1 Update frontend with API Gateway URL

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

## 7.2 Rebuild and redeploy frontend to S3

```bash
npm run build
aws s3 sync build/ s3://<your-frontend-bucket-name> --delete --exclude "images/*"
```

## 7.3 Invalidate CloudFront Cache from AWS Console or using AWS CLI

Go to CloudFront Distribution -> Invalidations -> Create invalidation -> Object paths: `/*` -> Create invalidation

OR 

Using AWS CLI:
```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

DISTRIBUTION_ID=$(aws cloudfront list-distributions \
  --query "DistributionList.Items[?contains(Origins.Items[0].DomainName, 'ecommerce-frontend-${ACCOUNT_ID}')].Id" \
  --output text)

echo "DISTRIBUTION_ID=$DISTRIBUTION_ID"

aws cloudfront create-invalidation \
  --distribution-id $DISTRIBUTION_ID \
  --paths "/*"
```

Invalidation typically completes within 1 minute.


## 7.4 Test the Fully Integrated Application

Open your CloudFront URL in a browser:
```
https://<your-cloudfront-domain>
```

**Full test checklist:**
- Login / signup (Cognito)
- Product listing loads from backend
- Add items to the cart
- Go to cart and place a test order
- View order history

### Troubleshooting

**Products still not loading:**
- Confirm CloudFront invalidation has completed
- Verify the API Gateway URL in `aws-config.js` has no trailing slash
- Check API Gateway CORS configuration (Module 6)
- Ensure ECS services are healthy (Module 5)
- Go to browser -> Console/Network trace (Chrome - Developer Tools) and check for any error.
- Check CloudWatch logs for the failing service

**Authentication errors:**
- Verify Cognito User Pool ID and Client ID are correctly configured in aws-config.js

**502 / 504 errors:**
- Check ECS service health in the ECS Console


## Next Steps
Proceed to **[Module 8: Notification](./module08-notification.md)**
