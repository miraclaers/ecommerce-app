# Module 8: DNS & SSL (Custom Domain)

## Overview
Configure a custom domain with SSL certificate for your ecommerce application.

## Architecture
```
User → Route53 (DNS) → CloudFront (SSL) → S3 (Frontend)
                              ↓
                        API Gateway (Backend)
```

## Prerequisites
- A registered domain name (can register via Route53 or use existing)
- Completed Module 7 (CloudFront distribution)

## Resources to Create

### 1. Route53 Hosted Zone
- Domain: yourdomain.com
- Records: A record (alias to CloudFront)

### 2. ACM Certificate
- Domain: yourdomain.com, www.yourdomain.com
- Validation: DNS validation via Route53
- Region: us-east-1 (required for CloudFront)

### 3. Updated CloudFront Distribution
- Alternate domain names (CNAMEs)
- Custom SSL certificate

## Console Steps

### Step 1: Register Domain (if needed)

**Option A: Register via Route53**
1. Go to Route53 Console → Registered domains
2. Click "Register domain"
3. Search for available domain
4. Add to cart and complete registration
5. Wait for registration (can take up to 3 days, usually minutes)

**Option B: Use Existing Domain**
1. Update nameservers at your registrar to Route53 nameservers
2. Create hosted zone in Route53

### Step 2: Create Hosted Zone (if not auto-created)

1. Route53 Console → Hosted zones → Create hosted zone
2. Domain name: `yourdomain.com`
3. Type: Public hosted zone
4. Create
5. Note the 4 nameservers (NS records)
6. Update nameservers at your domain registrar

### Step 3: Request SSL Certificate in ACM

**IMPORTANT:** Certificate must be in us-east-1 region for CloudFront!

1. Go to ACM Console → **Switch to us-east-1 region**
2. Request certificate → Request a public certificate
3. Domain names:
   - `yourdomain.com`
   - `www.yourdomain.com`
   - `*.yourdomain.com` (optional, for subdomains)
4. Validation method: DNS validation
5. Key algorithm: RSA 2048
6. Request

### Step 4: Validate Certificate

1. In ACM, click on your certificate
2. Click "Create records in Route53" button
3. This automatically adds CNAME records to your hosted zone
4. Wait for validation (usually 5-30 minutes)
5. Status should change to "Issued"

### Step 5: Update CloudFront Distribution

1. CloudFront Console → Your distribution → Edit
2. Settings:
   - Alternate domain names (CNAMEs): Add `yourdomain.com` and `www.yourdomain.com`
   - Custom SSL certificate: Select your ACM certificate
3. Save changes
4. Wait for deployment (5-10 minutes)

### Step 6: Create Route53 Records

**A Record for root domain:**
1. Route53 → Hosted zones → Your domain
2. Create record:
   - Record name: Leave empty (root domain)
   - Record type: A
   - Alias: Yes
   - Route traffic to: Alias to CloudFront distribution
   - Choose distribution: Select your CloudFront distribution
   - Routing policy: Simple routing
3. Create record

**A Record for www:**
4. Create record:
   - Record name: `www`
   - Record type: A
   - Alias: Yes
   - Route traffic to: Alias to CloudFront distribution
   - Choose distribution: Select your CloudFront distribution
5. Create record

### Step 7: Update Cognito Callback URLs

1. Cognito Console → User pools → ecommerce-users
2. App integration → App client → Edit
3. Hosted UI settings:
   - Add callback URLs: `https://yourdomain.com`, `https://www.yourdomain.com`
   - Add sign-out URLs: `https://yourdomain.com`, `https://www.yourdomain.com`
4. Save

### Step 8: Update Frontend Configuration

1. Rebuild frontend with production domain:

**Update `frontend/react-app/src/aws-config.js`:**
```javascript
const awsConfig = {
  Auth: {
    Cognito: {
      userPoolId: 'ap-south-1_xxxxxxxxx',
      userPoolClientId: 'xxxxxxxxxxxxxxxxxxxxxxxxxx',
      loginWith: {
        oauth: {
          domain: 'ecommerce-xxxxx.auth.ap-south-1.amazoncognito.com',
          scopes: ['openid', 'email', 'profile'],
          redirectSignIn: ['https://yourdomain.com'],
          redirectSignOut: ['https://yourdomain.com'],
          responseType: 'code'
        }
      }
    }
  }
};
```

2. **Rebuild and deploy:**
   - Build: `npm run build`
   - Upload to S3 bucket
   - Invalidate CloudFront cache

### Step 9: Test Custom Domain

**Test in Browser:**
1. **Open browser:** `https://yourdomain.com`
2. **Verify SSL certificate:** Should show secure/valid certificate (green lock icon)
3. **Test all functionality:**
   - Browse products (should load from API)
   - Sign in/Sign up (Cognito authentication)
   - Add items to cart
   - Place test order
   - Check that all features work with custom domain

**Expected Results:**
- Website loads with custom domain
- SSL certificate is valid (green lock icon)
- All API calls work properly
- Authentication flows work correctly
- No mixed content warnings

## CLI Commands (Optional)

For users who prefer command-line verification and testing:

## Optional: Custom Domain for API Gateway

If you want a custom domain for your API (e.g., `api.yourdomain.com`):

### Create API Gateway Custom Domain

1. API Gateway Console → Custom domain names → Create
2. Domain name: `api.yourdomain.com`
3. ACM certificate: Select your wildcard certificate
4. Endpoint type: Regional
5. Create

### Add API Mapping

1. API mappings tab → Configure API mappings
2. API: ecommerce-api
3. Stage: $default
4. Path: Leave empty
5. Save

### Create Route53 Record

1. Route53 → Hosted zones → Your domain
2. Create record:
   - Name: `api`
   - Type: A
   - Alias: Yes
   - Route traffic to: Alias to API Gateway API
   - Choose API: Select your custom domain
3. Create

### Update Frontend
```javascript
const API_BASE_URL = 'https://api.yourdomain.com';
```

You have successfully deployed a production-ready ecommerce application on AWS with custom domain and SSL certificate.
