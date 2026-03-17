# Module 6: Frontend Deployment

## Overview
Deploy the React frontend application to S3 with CloudFront distribution for global content delivery and HTTPS support.

## What We'll Build
- **6.1** S3 bucket for static website hosting
- **6.2** Build and configure React application
- **6.3** Upload frontend files to S3
- **6.4** CloudFront distribution for CDN and HTTPS
- **6.5** Configure custom error pages for React Router
- **6.6** Test frontend deployment and API integration

## Architecture
```
User → CloudFront (CDN) → S3 Bucket (Static Website) → API Gateway (Backend)
```

---

## 6.1 Create S3 Bucket for Frontend

### S3 Bucket Configuration

1. **S3 Console → Buckets → Create bucket**
2. **Bucket name:** `ecommerce-frontend-<random-number>` (must be globally unique)
3. **Region:** Choose your preferred region
4. **Block all public access:** Keep checked (CloudFront will access privately)
5. **Bucket versioning:** Disable
6. **Encryption:** Enable (SSE-S3)
7. **Create bucket**

---

## 6.2 Configure React Application

### Update Environment Configuration

1. **Navigate to frontend directory:**
```bash
cd frontend/react-app
```

2. **Update AWS configuration file:**

Edit `src/aws-config.js`:
```javascript
const awsConfig = {
  Auth: {
    Cognito: {
      userPoolId: '<COGNITO_USER_POOL_ID>', // e.g., ap-south-1_xxxxxxxxx
      userPoolClientId: '<COGNITO_CLIENT_ID>', // e.g., 1a2b3c4d5e6f7g8h9i0j1k2l3m
      loginWith: {
        email: true,
      },
    }
  },
  API: {
    baseUrl: '<API_GATEWAY_URL>' // e.g., https://xxxxxxxxxx.execute-api.us-east-1.amazonaws.com
  }
};

export default awsConfig;
```

### Build React Application

4. **Install dependencies:**
```bash
npm install
```

5. **Build for production:**
```bash
npm run build
```

This creates a `build/` directory with optimized production files.

6. **Upload build to S3:**
```bash
aws s3 sync build/ s3://<your-frontend-bucket-name> --delete
```

---

## 6.4 Create CloudFront Distribution

### Distribution Configuration

1. **CloudFront Console → Distributions → Create distribution**
2. **Origin domain:** Select your S3 bucket
3. **Origin access:** Origin access control settings (recommended)
4. **Create control setting:** Create new OAC
   - Name: `ecommerce-frontend-oac`
   - Sign requests: Yes
   - Click Create
5. **Viewer protocol policy:** Redirect HTTP to HTTPS
6. **Allowed HTTP methods:** GET, HEAD, OPTIONS, PUT, POST, PATCH, DELETE
7. **Cache policy:** Caching Optimized
8. **Origin request policy:** None
9. **Price class:** Use all edge locations (best performance)
10. **Default root object:** `index.html`
11. **Create distribution**

### Update S3 Bucket Policy

After creating the distribution, CloudFront will show a banner to update the S3 bucket policy:

1. **Copy the suggested bucket policy**
2. **Go to S3 bucket → Permissions → Bucket policy**
3. **Paste the policy**
4. **Save changes**

---

## 6.5 Test Frontend Deployment

### Get CloudFront URL

1. **Go to CloudFront distribution**
2. **Copy the Distribution domain name** (e.g., `d1234567890.cloudfront.net`)

### Test Application

**Test Frontend Loading:**
```bash
curl https://d1234567890.cloudfront.net
```

**Test in Browser:**
1. **Open:** `https://d1234567890.cloudfront.net`
2. **Verify:** React application loads
3. **Test navigation:** Different routes work (React Router)
4. **Test authentication:** Login/logout functionality
5. **Test API calls:** Product listing, cart operations


### Troubleshooting

**White screen/blank page:**
- Check browser console for JavaScript errors
- Verify all the values in aws_config.js 
- Check CloudFront error pages configuration
- Check CloudWatch logs for service specific errors

## Next Steps
Proceed to **[Module 7: Notification](./module07-notification.md)** to set up SNS and SQS for notifications.
