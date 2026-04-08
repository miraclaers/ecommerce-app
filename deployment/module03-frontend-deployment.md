# Module 3: Frontend Deployment

## Overview
Set up the infrastructure for the React frontend, configure it with Cognito values, deploy it to S3 and access it through CloudFront.
This lets you test login/signup functionality early.

Note: Product listing and other API-dependent features will work after **Module 7: Frontend-Backend Integration**, once backend is fully deployed along with APIs.

## In this module
- Create S3 bucket for hosting frontend build assets
- Create CloudFront distribution with S3 origin
- Configure CloudFront Root document and Custom Error Pages
- Configure and Build React Application and Deploy to S3
- Test login/signup functionality

## Architecture
<img width="800" height="447" alt="image" src="https://github.com/user-attachments/assets/a2db16a9-026b-4186-a98e-8528bc6c788b" />

## 3.1 Create S3 Bucket for Frontend

### S3 Bucket Configuration

1. **S3 Console → Buckets → Create bucket -> General Purpose**
2. **Bucket name:** `ecommerce-frontend-<some-number-or-text>` (must be globally unique)
3. **Region:** Your AWS region (Make sure you are in the right AWS region for S3 console)
4. **Block all public access:** Keep checked (CloudFront will access this bucket privately)
5. **Bucket versioning:** Disable
6. **Encryption:** Default - Enable (SSE-S3)
7. **Create bucket**

<details>
<summary><strong>CLI equivalent</strong></summary>

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=$(aws configure get region)
BUCKET_NAME=ecommerce-frontend-$ACCOUNT_ID

# For us-east-1, LocationConstraint is not required
if [ "$REGION" = "us-east-1" ]; then
  aws s3api create-bucket --bucket $BUCKET_NAME --region $REGION
else
  aws s3api create-bucket --bucket $BUCKET_NAME --region $REGION \
    --create-bucket-configuration LocationConstraint=$REGION
fi

echo "BUCKET_NAME=$BUCKET_NAME"
```

> Note: For `us-east-1`, omit `--create-bucket-configuration` as it is the default region.

</details>

## 3.2 Create CloudFront Distribution

### Distribution Configuration

1. **CloudFront Console → Distributions → Create distribution**
2. **Distribution name:** `ecommerce-distribution`
3. **Distribution type:** Single website or app -> Next
4. **Origin type:** Amazon S3
5. **Origin:** Select your frontend s3 bucket
6. **Settings:** Allow private S3 bucket access to CloudFront - Recommended
7. **Settings:** Use recommended cache settings tailored to serving S3 content -> Next
8. **Enable Security:** Select "Do not enable security protections"
9. **Create distribution**

### Check S3 Bucket Policy to allow access to CloudFront distribution

After creating the distribution, CloudFront automatically updates S3 bucket policy with something like following. Verify your S3 bucket policy.

Example:
```
{
    "Version": "2008-10-17",
    "Id": "PolicyForCloudFrontPrivateContent",
    "Statement": [
        {
            "Sid": "AllowCloudFrontServicePrincipal",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudfront.amazonaws.com"
            },
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::ecommerce-frontend-chetanag/*",
            "Condition": {
                "ArnLike": {
                    "AWS:SourceArn": "arn:aws:cloudfront::387258180757:distribution/E2P87PZZ9MQ3KE"
                }
            }
        }
    ]
}
```
If you don't see S3 Bucket policy updated, then modify the policy as per your **AWS Account**, **S3 Bucket Name** and **CloudFront Distribution ID**.

<details>
<summary><strong>CLI equivalent</strong></summary>

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Create Origin Access Control (reuse if already exists)
OAC_ID=$(aws cloudfront list-origin-access-controls \
  --query "OriginAccessControlList.Items[?Name=='ecommerce-oac'].Id" \
  --output text)

if [ -z "$OAC_ID" ]; then
  OAC_ID=$(aws cloudfront create-origin-access-control \
    --origin-access-control-config '{
      "Name": "ecommerce-oac",
      "OriginAccessControlOriginType": "s3",
      "SigningBehavior": "always",
      "SigningProtocol": "sigv4"
    }' \
    --query 'OriginAccessControl.Id' --output text)
fi

# Create CloudFront distribution
CF_DIST=$(aws cloudfront create-distribution \
  --distribution-config "{
    \"CallerReference\": \"ecommerce-$(date +%s)\",
    \"Comment\": \"ecommerce-distribution\",
    \"DefaultRootObject\": \"index.html\",
    \"Origins\": {
      \"Quantity\": 1,
      \"Items\": [{
        \"Id\": \"s3-origin\",
        \"DomainName\": \"${BUCKET_NAME}.s3.ap-south-1.amazonaws.com\",
        \"S3OriginConfig\": {\"OriginAccessIdentity\": \"\"},
        \"OriginAccessControlId\": \"${OAC_ID}\"
      }]
    },
    \"DefaultCacheBehavior\": {
      \"TargetOriginId\": \"s3-origin\",
      \"ViewerProtocolPolicy\": \"redirect-to-https\",
      \"CachePolicyId\": \"658327ea-f89d-4fab-a63d-7e88639e58f6\",
      \"AllowedMethods\": {\"Quantity\": 2, \"Items\": [\"GET\",\"HEAD\"], \"CachedMethods\": {\"Quantity\": 2, \"Items\": [\"GET\",\"HEAD\"]}}
    },
    \"Enabled\": true
  }")

CF_DIST_ID=$(echo $CF_DIST | python3 -c "import sys,json; d=json.load(sys.stdin)['Distribution']; print(d['Id'])")
CF_DOMAIN=$(echo $CF_DIST | python3 -c "import sys,json; d=json.load(sys.stdin)['Distribution']; print(d['DomainName'])")

echo "CF_DIST_ID=$CF_DIST_ID"
echo "CF_DOMAIN=$CF_DOMAIN"

# Apply S3 bucket policy to allow CloudFront OAC access
aws s3api put-bucket-policy \
  --bucket $BUCKET_NAME \
  --policy "{
    \"Version\": \"2008-10-17\",
    \"Statement\": [{
      \"Effect\": \"Allow\",
      \"Principal\": {\"Service\": \"cloudfront.amazonaws.com\"},
      \"Action\": \"s3:GetObject\",
      \"Resource\": \"arn:aws:s3:::${BUCKET_NAME}/*\",
      \"Condition\": {\"ArnLike\": {\"AWS:SourceArn\": \"arn:aws:cloudfront::${ACCOUNT_ID}:distribution/${CF_DIST_ID}\"}}
    }]
  }"
```

</details>

## 3.3 Configure CloudFront Root document and Custom Error Pages

React is a single-page application (SPA). All routes must return `index.html` so React Router can handle navigation client-side.

1. **Go to your CloudFront distribution -> General** -> Edit -> Update Default root object: **index.html** -> Save changes
2. **Error pages → Create custom error response**
3. **HTTP error code:** 403
4. **Customize error response:** Yes
5. **Response page path:** `/index.html`
6. **HTTP response code:** 200
7. **Create**
8. **Repeat for HTTP error code 404**

**Save these values:**
- **CloudFront Distribution ID** (e.g., `E1234567890ABC`)
- **CloudFront Domain Name** (e.g., `d1234567890.cloudfront.net`)

<details>
<summary><strong>CLI equivalent</strong></summary>

```bash
# Get current distribution config (needed for update)
aws cloudfront get-distribution-config --id $CF_DIST_ID > /tmp/cf-config.json
ETAG=$(python3 -c "import json; print(json.load(open('/tmp/cf-config.json'))['ETag'])")

# Add custom error responses for 403 and 404 → index.html
python3 -c "
import json
cfg = json.load(open('/tmp/cf-config.json'))['DistributionConfig']
cfg['CustomErrorResponses'] = {
  'Quantity': 2,
  'Items': [
    {'ErrorCode': 403, 'ResponsePagePath': '/index.html', 'ResponseCode': '200', 'ErrorCachingMinTTL': 300},
    {'ErrorCode': 404, 'ResponsePagePath': '/index.html', 'ResponseCode': '200', 'ErrorCachingMinTTL': 300}
  ]
}
print(json.dumps(cfg))
" > /tmp/cf-config-updated.json

aws cloudfront update-distribution \
  --id $CF_DIST_ID \
  --if-match $ETAG \
  --distribution-config file:///tmp/cf-config-updated.json
```

</details>

## 3.4 Configure and Build React Application and Deploy to S3

At this point you should have Cognito User Pool and App Client values from Module 2. We will use these values to configure frontend so that the user registration and authentication flow will work. 
Note that, at this moment we don't have access to backend services (via API Gateway) and hence the product listing will show an error message until the API is connected (Module 7).

### In your local workstation

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

### Build and Deploy React frontend

3. **Install dependencies:**
```bash
npm install
```

4. **Build:**
```bash
npm run build
```

5. **Deploy frontend build to S3:**
```bash
aws s3 sync build/ s3://<your-frontend-bucket-name> --delete --exclude "images/*"
```

### Update Cognito Callback URL

6. **Cognito Console → User pools → ecommerce-app**
7. **App integration tab → App clients → Click your app client**
8. **Edit Login pages settings:**
   - **Allowed callback URLs:** Add `https://<your-cloudfront-domain>`
   - **Allowed sign-out URLs:** Add `https://<your-cloudfront-domain>`
9. **Save changes**

## 3.5 Test Login/Signup

Open your CloudFront URL in a browser:
```
https://<your-cloudfront-domain>
```

**What works now:**
- Sign up with email
- Email verification
- Login / logout

**Expected (not yet working):**
- Product listing — shows "Error loading products" (API not connected yet)
- Cart, Orders — require authentication + API

These will be fully functional after **Module 7: Frontend-Backend Integration**.

---

## Next Steps
Proceed to **[Module 4: Data Layer](./module04-data-layer.md)**
