# Module 7: Frontend-Backend Integration

## Overview
Now that the API Gateway is deployed, configure the React application with all required AWS values, build it, and deploy it to the S3 bucket created in Module 3.

## What We'll Do
- **7.1** Update `aws-config.js` with Cognito and API Gateway values
- **7.2** Build the React application
- **7.3** Upload the build to S3
- **7.4** Invalidate CloudFront cache
- **7.5** Update Cognito callback URL with CloudFront domain
- **7.6** Test the fully integrated application

## Prerequisites
You will need the following values collected from previous modules:

| Value | Where to Find |
|-------|--------------|
| Cognito User Pool ID | Module 2 → Cognito Console → User pools |
| Cognito App Client ID | Module 2 → Cognito Console → App clients |
| API Gateway URL | Module 6 → API Gateway Console → Stages → $default → Invoke URL |
| Frontend S3 Bucket Name | Module 3 → S3 Console |
| CloudFront Distribution ID | Module 3 → CloudFront Console |
| CloudFront Domain Name | Module 3 → CloudFront Console |

---

## 7.1 Update AWS Configuration

1. **Navigate to frontend directory:**
```bash
cd frontend/react-app
```

2. **Edit `src/aws-config.js`:**
```javascript
const awsConfig = {
  Auth: {
    Cognito: {
      userPoolId: '<COGNITO_USER_POOL_ID>',       // e.g., ap-south-1_xxxxxxxxx
      userPoolClientId: '<COGNITO_CLIENT_ID>',    // e.g., 1a2b3c4d5e6f7g8h9i0j1k2l3m
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

Replace the placeholders with your actual values.

---

## 7.2 Build the React Application

1. **Install dependencies:**
```bash
npm install
```

2. **Build for production:**
```bash
npm run build
```

This creates a `build/` directory with optimized production files.

---

## 7.3 Upload Build to S3

```bash
aws s3 sync build/ s3://<your-frontend-bucket-name> --delete
```

Replace `<your-frontend-bucket-name>` with the bucket name from Module 3.

---

## 7.4 Invalidate CloudFront Cache

CloudFront caches content at edge locations. After uploading new files, invalidate the cache so users get the latest version:

```bash
aws cloudfront create-invalidation \
  --distribution-id <your-cloudfront-distribution-id> \
  --paths "/*"
```

Replace `<your-cloudfront-distribution-id>` with the Distribution ID from Module 3.

**Note:** Invalidation typically completes within 1-2 minutes.

---

## 7.5 Update Cognito Callback URL

Now that you have the CloudFront domain, update the Cognito app client with the correct callback URL:

1. **Cognito Console → User pools → ecommerce-app**
2. **App integration tab → App clients → Click your app client**
3. **Edit Hosted UI settings:**
   - **Allowed callback URLs:** Add `https://<your-cloudfront-domain>` (e.g., `https://d1234567890.cloudfront.net`)
   - **Allowed sign-out URLs:** Add `https://<your-cloudfront-domain>`
4. **Save changes**

---

## 7.6 Test the Application

### Get CloudFront URL

Your application is available at the CloudFront domain from Module 3:
```
https://<your-cloudfront-domain>
```

### Test Checklist

**Test Frontend Loading:**
```bash
curl https://<your-cloudfront-domain>
```

**Test in Browser:**
1. **Open:** `https://<your-cloudfront-domain>`
2. **Verify:** React application loads correctly
3. **Test navigation:** Different routes work (React Router)
4. **Test authentication:** Sign up, login, logout
5. **Test API calls:** Product listing loads from backend
6. **Test cart:** Add/remove items
7. **Test orders:** Place a test order

### Troubleshooting

**White screen / blank page:**
- Check browser console for JavaScript errors
- Verify all values in `aws-config.js` are correct
- Ensure CloudFront cache invalidation has completed
- Check CloudFront error pages are configured (Module 3)

**Authentication errors:**
- Verify Cognito User Pool ID and Client ID in `aws-config.js`
- Confirm CloudFront domain is added to Cognito callback URLs (step 7.5)

**API errors (CORS / 401 / 502):**
- Verify API Gateway URL in `aws-config.js` (no trailing slash)
- Check API Gateway CORS configuration (Module 6)
- Ensure ECS services are healthy (Module 5)

## Next Steps
Proceed to **[Module 8: Notification](./module08-notification.md)** to set up SNS and SQS for order notifications.
