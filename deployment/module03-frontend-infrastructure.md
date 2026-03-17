# Module 3: Frontend Infrastructure

## Overview
Set up the hosting infrastructure for the React frontend application — an S3 bucket and CloudFront distribution. The actual application build and deployment will happen in **Module 7: Frontend-Backend Integration**, once the API Gateway URL is available.

## What We'll Build
- **3.1** S3 bucket for static website hosting
- **3.2** CloudFront distribution for CDN and HTTPS
- **3.3** Configure custom error pages for React Router

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

React is a single-page application (SPA). All routes must return `index.html` so the React Router can handle navigation client-side.

1. **Go to your CloudFront distribution → Error pages → Create custom error response**
2. **HTTP error code:** 403
3. **Customize error response:** Yes
4. **Response page path:** `/index.html`
5. **HTTP response code:** 200
6. **Create**
7. **Repeat for HTTP error code 404**

---

## What's Next

The S3 bucket and CloudFront distribution are now ready. The frontend application will be built and deployed in **Module 7: Frontend-Backend Integration**, after the API Gateway URL is available.

You will need the following values in Module 7:
- Frontend S3 bucket name
- CloudFront Distribution ID

## Next Steps
Proceed to **[Module 4: Data Layer](./module04-data-layer.md)** to set up DynamoDB, RDS, and Parameter Store.
