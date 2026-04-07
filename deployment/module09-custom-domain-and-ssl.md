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

<details>
<summary><strong>CLI equivalent</strong></summary>

```bash
HOSTED_ZONE_ID=$(aws route53 create-hosted-zone \
  --name yourdomain.com \
  --caller-reference $(date +%s) \
  --query 'HostedZone.Id' --output text | cut -d/ -f3)

# View the NS records to update at your registrar
aws route53 list-resource-record-sets \
  --hosted-zone-id $HOSTED_ZONE_ID \
  --query "ResourceRecordSets[?Type=='NS'].ResourceRecords[].Value" \
  --output text

echo "HOSTED_ZONE_ID=$HOSTED_ZONE_ID"
```

</details>

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

<details>
<summary><strong>CLI equivalent</strong></summary>

```bash
# Certificate MUST be requested in us-east-1 for CloudFront
CERT_ARN=$(aws acm request-certificate \
  --region us-east-1 \
  --domain-name yourdomain.com \
  --subject-alternative-names www.yourdomain.com \
  --validation-method DNS \
  --query 'CertificateArn' --output text)

echo "CERT_ARN=$CERT_ARN"

# Get the CNAME validation record and add it to Route53
CNAME_NAME=$(aws acm describe-certificate \
  --region us-east-1 \
  --certificate-arn $CERT_ARN \
  --query 'Certificate.DomainValidationOptions[0].ResourceRecord.Name' --output text)

CNAME_VALUE=$(aws acm describe-certificate \
  --region us-east-1 \
  --certificate-arn $CERT_ARN \
  --query 'Certificate.DomainValidationOptions[0].ResourceRecord.Value' --output text)

aws route53 change-resource-record-sets \
  --hosted-zone-id $HOSTED_ZONE_ID \
  --change-batch "{
    \"Changes\": [{
      \"Action\": \"CREATE\",
      \"ResourceRecordSet\": {
        \"Name\": \"$CNAME_NAME\",
        \"Type\": \"CNAME\",
        \"TTL\": 300,
        \"ResourceRecords\": [{\"Value\": \"$CNAME_VALUE\"}]
      }
    }]
  }"

# Wait for certificate to be issued
aws acm wait certificate-validated \
  --region us-east-1 \
  --certificate-arn $CERT_ARN
```

</details>

## 9.3: Add alternate domain name for CloudFront Distribution

1. CloudFront Console → Your distribution → Edit
2. Settings:
   - Alternate domain names (CNAMEs): Add `yourdomain.com` and `www.yourdomain.com`
   - Custom SSL certificate: Select your ACM certificate
3. Save changes
4. Wait for deployment (5-10 minutes)

<details>
<summary><strong>CLI equivalent</strong></summary>

```bash
# Get current config
aws cloudfront get-distribution-config --id $CF_DIST_ID > /tmp/cf-config.json
ETAG=$(python3 -c "import json; print(json.load(open('/tmp/cf-config.json'))['ETag'])")

# Add alternate domain names and SSL certificate
python3 -c "
import json
cfg = json.load(open('/tmp/cf-config.json'))['DistributionConfig']
cfg['Aliases'] = {'Quantity': 2, 'Items': ['yourdomain.com', 'www.yourdomain.com']}
cfg['ViewerCertificate'] = {
  'ACMCertificateArn': '$CERT_ARN',
  'SSLSupportMethod': 'sni-only',
  'MinimumProtocolVersion': 'TLSv1.2_2021'
}
print(json.dumps(cfg))
" > /tmp/cf-config-domain.json

aws cloudfront update-distribution \
  --id $CF_DIST_ID \
  --if-match $ETAG \
  --distribution-config file:///tmp/cf-config-domain.json
```

</details>

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

<details>
<summary><strong>CLI equivalent</strong></summary>

```bash
# CloudFront always uses us-east-1 hosted zone ID Z2FDTNDATAQYW2 for alias records
aws route53 change-resource-record-sets \
  --hosted-zone-id $HOSTED_ZONE_ID \
  --change-batch "{
    \"Changes\": [
      {
        \"Action\": \"CREATE\",
        \"ResourceRecordSet\": {
          \"Name\": \"yourdomain.com\",
          \"Type\": \"A\",
          \"AliasTarget\": {
            \"HostedZoneId\": \"Z2FDTNDATAQYW2\",
            \"DNSName\": \"$CF_DOMAIN\",
            \"EvaluateTargetHealth\": false
          }
        }
      },
      {
        \"Action\": \"CREATE\",
        \"ResourceRecordSet\": {
          \"Name\": \"www.yourdomain.com\",
          \"Type\": \"A\",
          \"AliasTarget\": {
            \"HostedZoneId\": \"Z2FDTNDATAQYW2\",
            \"DNSName\": \"$CF_DOMAIN\",
            \"EvaluateTargetHealth\": false
          }
        }
      }
    ]
  }"
```

</details>

## 9.5: Update Cognito Callback URLs

1. Cognito Console → User pools → your user pool
2. App integration → App client → Edit
3. Hosted UI settings:
   - Add callback URLs: `https://yourdomain.com`, `https://www.yourdomain.com`
   - Add sign-out URLs: `https://yourdomain.com`, `https://www.yourdomain.com`
4. Save

<details>
<summary><strong>CLI equivalent</strong></summary>

```bash
aws cognito-idp update-user-pool-client \
  --user-pool-id $USER_POOL_ID \
  --client-id $CLIENT_ID \
  --callback-urls "https://yourdomain.com" "https://www.yourdomain.com" \
  --logout-urls "https://yourdomain.com" "https://www.yourdomain.com" \
  --explicit-auth-flows ALLOW_USER_PASSWORD_AUTH ALLOW_USER_SRP_AUTH ALLOW_REFRESH_TOKEN_AUTH
```

</details>

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
