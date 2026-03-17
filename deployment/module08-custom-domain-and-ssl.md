# Module 8: Custom Domain & SSL 

## Overview
Configure a custom domain with SSL certificate for your ecommerce application.

## Architecture
```
User → Route53 (DNS) → CloudFront (SSL) → S3 (Frontend)
                              ↓
                        API Gateway (Backend)
```

## Prerequisites
- A registered domain name (can register via Route53 or use existing). I have my domain purchased from GoDaddy and DNS is managed in Route53 Public Hosted Zone.
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

### Step 1: Create Hosted Zone (if not auto-created)

1. Route53 Console → Hosted zones → Create hosted zone
2. Domain name: `yourdomain.com`
3. Type: Public hosted zone
4. Create
5. Note the 4 nameservers (NS records)
6. Update nameservers at your domain registrar

### Step 2: Request SSL Certificate in ACM

**IMPORTANT:** Certificate must be in us-east-1 region for CloudFront!

1. Go to ACM Console → **Switch to us-east-1 region**
2. Request certificate → Request a public certificate
3. Domain names:
   - `yourdomain.com`
   - `www.yourdomain.com`
   - `*.yourdomain.com` (optional, for subdomains)
4. Validation method: DNS validation
5. Request

### Step 3: Validate Certificate

1. In ACM, click on your certificate
2. Click "Create records in Route53" button
3. This automatically adds CNAME records to your hosted zone
4. Wait for validation (usually 5-30 minutes)
5. Status should change to "Issued"

### Step 4: Update CloudFront Distribution

1. CloudFront Console → Your distribution → Edit
2. Settings:
   - Alternate domain names (CNAMEs): Add `yourdomain.com` and `www.yourdomain.com`
   - Custom SSL certificate: Select your ACM certificate
3. Save changes
4. Wait for deployment (5-10 minutes)

### Step 5: Create Route53 Records

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

### Step 6: Update Cognito Callback URLs

1. Cognito Console → User pools → ecommerce-users
2. App integration → App client → Edit
3. Hosted UI settings:
   - Add callback URLs: `https://yourdomain.com`, `https://www.yourdomain.com`
   - Add sign-out URLs: `https://yourdomain.com`, `https://www.yourdomain.com`
4. Save

### Step 7: Test Custom Domain

**Test in Browser:**
1. **Open browser:** `https://yourdomain.com`
2. **Verify SSL certificate:** Should show secure/valid certificate (green lock icon)
3. **Test all functionality:**
   - Browse products (should load from API)
   - Sign in/Sign up (Cognito authentication)
   - Add items to cart
   - Place test order
   - Check that all features work with custom domain

Congratulations ! You have successfully deployed a production-ready ecommerce application on AWS with custom domain and SSL certificate.

## Next Steps
Proceed to **[Module 9: Cleanup](./module09-cleanup.md)** to remove all AWS resources and avoid ongoing charges.
