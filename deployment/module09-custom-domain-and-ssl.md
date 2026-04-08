# Module 9: Custom Domain & SSL 

## Overview
Access application using Custom domain name and enable HTTPS with SSL certificate

## Architecture
<img width="800" height="370" alt="image" src="https://github.com/user-attachments/assets/037a564f-6dd8-41ea-8822-7a969adae54b" />


## Prerequisites
- A registered public domain name (can register via Route53 or use existing).
- Amazon Route 53 should be configured as DNS provider for your domain name.

## In this module
- Get Public SSL Certificate from Amazon Certificate Manager (in us-east-1 region)
- Add alternate domain name for CloudFront Distribution
- Create DNS records for your domain name pointing to CloudFront distribution
- Test the application access over custom domain name

## 9.1 Route 53 Public Hosted Zone (pre-requisite)
If you don't have it already:

1. Route53 Console → Hosted zones → Create hosted zone
2. Domain name: `yourdomain.com`
3. Type: Public hosted zone
4. Create
5. Note the 4 nameservers (NS records)
6. Update nameservers at your domain registrar

## 9.2 Request SSL Certificate in ACM

**IMPORTANT:** Certificate must be in us-east-1 region for CloudFront!

### Request Certificate

1. Go to ACM Console → **Switch to us-east-1 region**
2. Request certificate → Request a public certificate
3. Domain names:
   - `yourdomain.com`
   - `www.yourdomain.com`
   - `*.yourdomain.com` (optional, for subdomains)
4. Validation method: DNS validation
5. Request

### Validate Certificate

1. In ACM, click on your certificate
2. Click "Create records in Route53" button
3. This automatically adds CNAME records to your hosted zone
4. Wait for validation (usually 1-2 minutes)
5. Status should change to "Issued"

## 9.3: Add alternate domain name for CloudFront Distribution

1. CloudFront Console → Your distribution → Edit
2. Settings:
   - Alternate domain names (CNAMEs): Add `yourdomain.com` and `www.yourdomain.com`
   - Custom SSL certificate: Select your ACM certificate
3. Save changes
4. Wait for deployment (5-10 minutes)

## 9.4: Create Route53 Records

**A Record for Top level domain:**
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
1. Create record:
   - Record name: `www`
   - Record type: A
   - Alias: Yes
   - Route traffic to: Alias to CloudFront distribution
   - Choose distribution: Select your CloudFront distribution
2. Create record

## 9.5: Update Cognito Callback URLs

1. Cognito Console → User pools → your user pool
2. App integration → App client → Edit
3. Hosted UI settings:
   - Add callback URLs: `https://yourdomain.com`, `https://www.yourdomain.com`
   - Add sign-out URLs: `https://yourdomain.com`, `https://www.yourdomain.com`
4. Save

## 9.6: Test the Application with Custom Domain

**Test in Browser:**
1. **Open browser:** `https://yourdomain.com`
2. **Verify SSL certificate:** Should show secure/valid certificate (green lock icon)
3. **Test all functionality:**
   - Browse products (should load from API)
   - Sign in/Sign up (Cognito authentication)
   - Add items to cart
   - Place test order
   - Check that all features work

Congratulations ! You have successfully deployed a production-ready ecommerce application on AWS with custom domain and SSL certificate.

## Next Steps
Proceed to **[Module 10: Cleanup](./module10-cleanup.md)**
