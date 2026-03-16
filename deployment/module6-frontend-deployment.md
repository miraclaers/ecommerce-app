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

2. **Create production environment file:**
```bash
# Create .env.production file
echo "REACT_APP_API_URL=https://<your-api-gateway-url>" > .env.production
```

3. **Update AWS configuration file:**

Edit `src/aws-config.js`:
```javascript
const awsConfig = {
  Auth: {
    Cognito: {
      userPoolId: '<your-user-pool-id>',
      userPoolClientId: '<your-app-client-id>',
      loginWith: {
        oauth: {
          scopes: ['openid', 'email', 'profile'],
          redirectSignIn: ['https://<your-cloudfront-domain>'],
          redirectSignOut: ['https://<your-cloudfront-domain>'],
          responseType: 'code'
        }
      }
    }
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

---

## 6.3 Upload Files to S3

### Upload Build Files

1. **Go to S3 bucket → Upload**
2. **Select all files from `build/` directory**
   - Include all files and folders (static/, index.html, etc.)
3. **Upload**

### Enable Static Website Hosting

1. **Go to bucket → Properties → Static website hosting**
2. **Enable static website hosting**
3. **Index document:** `index.html`
4. **Error document:** `index.html` (for React Router support)
5. **Save changes**

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

## 6.5 Configure Error Pages

### Custom Error Pages for React Router

1. **Go to CloudFront distribution → Error pages → Create custom error response**

**404 Error Page:**
2. **HTTP error code:** 404
3. **Customize error response:** Yes
4. **Response page path:** `/index.html`
5. **HTTP response code:** 200
6. **Create custom error response**

**403 Error Page:**
7. **Create another custom error response**
8. **HTTP error code:** 403
9. **Customize error response:** Yes
10. **Response page path:** `/index.html`
11. **HTTP response code:** 200
12. **Create custom error response**

---

## 6.6 Test Frontend Deployment

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

### Verify Integration

**Check API Integration:**
- Products page loads data from API Gateway
- Authentication redirects work properly
- Protected routes require login
- API calls include proper CORS headers

**Check Performance:**
- Static assets load from CloudFront edge locations
- HTTPS certificate works properly
- Caching headers are set correctly

### Update Cognito Redirect URLs

1. **Cognito Console → User pools → ecommerce-users**
2. **App integration → App clients → ecommerce-web-client**
3. **Edit Hosted UI settings**
4. **Allowed callback URLs:** Add `https://d1234567890.cloudfront.net`
5. **Allowed sign-out URLs:** Add `https://d1234567890.cloudfront.net`
6. **Save changes**

### Troubleshooting

**White screen/blank page:**
- Check browser console for JavaScript errors
- Verify API_URL in environment configuration
- Check CloudFront error pages configuration

**API calls failing:**
- Verify CORS configuration in API Gateway
- Check API Gateway URL in frontend configuration
- Ensure JWT tokens are being sent properly

**Authentication not working:**
- Update Cognito callback URLs with CloudFront domain
- Check aws-config.js has correct User Pool settings
- Verify redirect URLs match exactly

## Next Steps
Proceed to **[Module 7: Event-Driven Architecture](./module7-event-driven.md)** to set up SNS and SQS for notifications.
