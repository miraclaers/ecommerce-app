# Module 3: Frontend Infrastructure

## Overview
Set up the hosting infrastructure for the React frontend, configure it with Cognito values, and deploy it to S3. This lets you test login/signup functionality early. Product listing and other API-dependent features will work after **Module 7: Frontend-Backend Integration**, once the API Gateway URL is available.

## What We'll Build
- **3.1** S3 bucket for static website hosting
- **3.2** CloudFront distribution for CDN and HTTPS
- **3.3** Configure custom error pages for React Router
- **3.4** Configure and deploy the React application (Cognito only)
- **3.5** Test login/signup functionality

## Architecture
```
User → CloudFront (CDN) → S3 Bucket (Static Website)
```

---

## 3.1 Create S3 Bucket for Frontend

### S3 Bucket Configuration

1. **S3 Console → Buckets → Create bucket**
2. **Bucket name:** `ecommerce-frontend-<random-number>` (must be globally unique)
3. **Region:** Choose your preferred region
4. **Block all public access:** Keep checked (CloudFront will access privately)
5. **Bucket versioning:** Disable
6. **Encryption:** Enable (SSE-S3)
7. **Create bucket**

### Save This Value
- **Frontend Bucket Name** (e.g., `ecommerce-frontend-12345`)

---

## 3.2 Create CloudFront Distribution

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

### Save These Values
- **CloudFront Distribution ID** (e.g., `E1234567890ABC`)
- **CloudFront Domain Name** (e.g., `d1234567890.cloudfront.net`)

---

## 3.3 Configure Custom Error Pages for React Router

React is a single-page application (SPA). All routes must return `index.html` so React Router can handle navigation client-side.

1. **Go to your CloudFront distribution → Error pages → Create custom error response**
2. **HTTP error code:** 403
3. **Customize error response:** Yes
4. **Response page path:** `/index.html`
5. **HTTP response code:** 200
6. **Create**
7. **Repeat for HTTP error code 404**

---

## 3.4 Configure and Deploy the React Application

At this point you have Cognito values from Module 2 but no API Gateway URL yet. You can still build and deploy the frontend — the app will load and authentication will work. Product listing will show an error message until the API is connected in Module 7.

### Update AWS Configuration

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
    baseUrl: ''  // Leave empty for now — will be updated in Module 7
  }
};

export default awsConfig;
```

### Build and Deploy

3. **Install dependencies:**
```bash
npm install
```

4. **Build for production:**
```bash
npm run build
```

5. **Upload to S3:**
```bash
aws s3 sync build/ s3://<your-frontend-bucket-name> --delete
```

### Update Cognito Callback URL

6. **Cognito Console → User pools → ecommerce-app**
7. **App integration tab → App clients → Click your app client**
8. **Edit Hosted UI settings:**
   - **Allowed callback URLs:** Add `https://<your-cloudfront-domain>`
   - **Allowed sign-out URLs:** Add `https://<your-cloudfront-domain>`
9. **Save changes**

---

## 3.5 Test Login/Signup

Open your CloudFront URL in a browser:
```
https://<your-cloudfront-domain>
```

**What works now:**
- ✅ Sign up with email
- ✅ Email verification
- ✅ Login / logout

**Expected (not yet working):**
- ❌ Product listing — shows "Error loading products" (API not connected yet)
- ❌ Cart, Orders — require authentication + API

These will be fully functional after **Module 7: Frontend-Backend Integration**.

---

## Next Steps
Proceed to **[Module 4: Data Layer](./module04-data-layer.md)** to set up DynamoDB, RDS, and Parameter Store.
