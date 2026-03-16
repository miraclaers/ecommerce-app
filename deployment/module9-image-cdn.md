# Module 9: Image CDN with CloudFront

## Overview

This module sets up a CloudFront distribution to serve product images from S3 with improved performance, security, and global delivery.

### Architecture

```
Frontend → CloudFront Distribution → S3 Images Bucket (Private)
                                  → Origin Access Control (OAC)
```

### What You'll Build

- **S3 Images Bucket** - Private bucket for product images
- **CloudFront Distribution** - Global CDN for image delivery
- **Origin Access Control** - Secure S3 access from CloudFront only
- **DynamoDB Update** - Replace direct S3 URLs with CloudFront URLs

### Benefits

- **Performance** - Global edge locations for faster image loading
- **Security** - Private S3 bucket, access only through CloudFront
- **Cost** - Reduced S3 data transfer costs
- **Scalability** - Handle high traffic with CDN caching

---

## 9.1 Create S3 Images Bucket

### Create Bucket

1. **S3 Console → Create bucket**
2. **Bucket name:** `ecommerce-images-<random-suffix>` (e.g., `ecommerce-images-abc123`)
3. **Region:** Same as your other resources
4. **Block all public access:** ✅ **Enabled** (keep private)
5. **Bucket versioning:** Disabled
6. **Default encryption:** Server-side encryption with Amazon S3 managed keys (SSE-S3)
7. **Create bucket**

### Upload Product Images

8. **Download sample images** (if not already done):
   ```bash
   cd data
   ./download-product-images-v2.sh
   ```

9. **Upload images to new bucket:**
   ```bash
   aws s3 sync product-images/ s3://ecommerce-images-<your-suffix>/products/ --region <your-region>
   ```

10. **Verify upload:**
    ```bash
    aws s3 ls s3://ecommerce-images-<your-suffix>/products/ --region <your-region>
    ```

---

## 9.2 Create CloudFront Distribution

### Create Distribution

1. **CloudFront Console → Distributions → Create distribution**

### Origin Settings

2. **Origin domain:** Select your S3 images bucket
3. **Origin path:** `/products` (optional - serves images from /products folder)
4. **Name:** `ecommerce-images-origin`
5. **Origin access:** Origin access control settings (recommended)
6. **Origin access control:** Create new OAC
   - **Name:** `ecommerce-images-oac`
   - **Description:** `OAC for ecommerce product images`
   - **Origin type:** S3
   - **Create**

### Default Cache Behavior

7. **Viewer protocol policy:** Redirect HTTP to HTTPS
8. **Allowed HTTP methods:** GET, HEAD
9. **Cache policy:** Managed-CachingOptimized
10. **Origin request policy:** None
11. **Response headers policy:** None

### Distribution Settings

12. **Price class:** Use all edge locations (best performance)
13. **Alternate domain name (CNAME):** Leave empty for now
14. **Custom SSL certificate:** Default CloudFront SSL certificate
15. **Default root object:** Leave empty
16. **Description:** `CDN for ecommerce product images`
17. **Create distribution**

### Note Distribution Domain

18. **Copy the distribution domain name** (e.g., `d1234567890123.cloudfront.net`)
19. **Wait for deployment** (Status: Deployed) - takes 5-10 minutes

---

## 9.3 Configure S3 Bucket Policy

### Update Bucket Policy

1. **Go to S3 bucket → Permissions → Bucket policy**
2. **CloudFront will show a banner** "Update S3 bucket policy"
3. **Click "Copy policy"** from the CloudFront console banner
4. **Paste the policy** in S3 bucket policy editor

**Or manually create policy:**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowCloudFrontServicePrincipal",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudfront.amazonaws.com"
      },
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::ecommerce-images-<your-suffix>/*",
      "Condition": {
        "StringEquals": {
          "AWS:SourceArn": "arn:aws:cloudfront::<account-id>:distribution/<distribution-id>"
        }
      }
    }
  ]
}
```

5. **Replace placeholders:**
   - `<your-suffix>` - Your bucket suffix
   - `<account-id>` - Your AWS account ID
   - `<distribution-id>` - Your CloudFront distribution ID

6. **Save changes**

---

## 9.4 Test CloudFront Distribution

### Test Image Access

1. **Get an image filename** from your S3 bucket:
   ```bash
   aws s3 ls s3://ecommerce-images-<your-suffix>/products/ --region <your-region>
   ```

2. **Test CloudFront URL:**
   ```
   https://<distribution-domain>/image-filename.jpg
   ```
   Example: `https://d1234567890123.cloudfront.net/laptop-1.jpg`

3. **Verify image loads** in browser

### Test S3 Direct Access (Should Fail)

4. **Try direct S3 URL** (should return Access Denied):
   ```
   https://ecommerce-images-<your-suffix>.s3.<region>.amazonaws.com/products/laptop-1.jpg
   ```

This confirms images are only accessible through CloudFront.

---

## 9.5 Update DynamoDB Image URLs

### Create Update Script

1. **Create script:** `data/update-image-urls-cloudfront.py`

```python
#!/usr/bin/env python3
import boto3
import sys
import json
from decimal import Decimal

def update_image_urls(region, cloudfront_domain):
    """Update DynamoDB product image URLs to use CloudFront"""
    
    dynamodb = boto3.resource('dynamodb', region_name=region)
    table = dynamodb.Table('ecommerce-products')
    
    try:
        # Scan all products
        response = table.scan()
        products = response['Items']
        
        updated_count = 0
        
        for product in products:
            product_id = product['product_id']
            current_image_url = product.get('image_url', '')
            
            # Skip if already using CloudFront
            if cloudfront_domain in current_image_url:
                print(f"Skipping {product_id} - already using CloudFront")
                continue
            
            # Extract filename from current URL
            if 's3.amazonaws.com' in current_image_url or 's3.' in current_image_url:
                filename = current_image_url.split('/')[-1]
                new_image_url = f"https://{cloudfront_domain}/{filename}"
                
                # Update the product
                table.update_item(
                    Key={'product_id': product_id},
                    UpdateExpression='SET image_url = :url',
                    ExpressionAttributeValues={':url': new_image_url}
                )
                
                print(f"Updated {product_id}: {filename}")
                updated_count += 1
            else:
                print(f"Skipping {product_id} - URL format not recognized")
        
        print(f"\nSuccessfully updated {updated_count} products")
        
    except Exception as e:
        print(f"Error updating image URLs: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 update-image-urls-cloudfront.py <region> <cloudfront-domain>")
        print("Example: python3 update-image-urls-cloudfront.py us-east-1 d1234567890123.cloudfront.net")
        sys.exit(1)
    
    region = sys.argv[1]
    cloudfront_domain = sys.argv[2]
    
    print(f"Updating image URLs to use CloudFront domain: {cloudfront_domain}")
    update_image_urls(region, cloudfront_domain)
```

2. **Make script executable:**
   ```bash
   chmod +x data/update-image-urls-cloudfront.py
   ```

### Run Update Script

3. **Update DynamoDB with CloudFront URLs:**
   ```bash
   cd data
   python3 update-image-urls-cloudfront.py <your-region> <your-cloudfront-domain>
   ```
   
   Example:
   ```bash
   python3 update-image-urls-cloudfront.py us-east-1 d1234567890123.cloudfront.net
   ```

### Verify Updates

4. **Check updated URLs:**
   ```bash
   aws dynamodb scan \
     --table-name ecommerce-products \
     --projection-expression "product_id, image_url" \
     --region <your-region>
   ```

5. **Test frontend** - Product images should now load from CloudFront

---

## 9.6 Performance Optimization

### Configure Cache Behaviors

1. **CloudFront Console → Your distribution → Behaviors**
2. **Edit default behavior:**
   - **TTL Settings:** Use cache policy
   - **Cache policy:** Managed-CachingOptimized
   - **Compress objects automatically:** Yes

### Add Custom Cache Policy (Optional)

3. **Create cache policy for images:**
   - **Name:** `ecommerce-images-cache`
   - **TTL:** Min 1 day, Default 7 days, Max 365 days
   - **Cache key:** Include only origin domain name
   - **Compression:** Enabled

---

## 9.7 Monitoring and Troubleshooting

### CloudWatch Metrics

1. **CloudFront Console → Monitoring**
2. **Key metrics to monitor:**
   - **Requests** - Total requests to distribution
   - **Cache hit rate** - Percentage of cached responses
   - **Error rate** - 4xx and 5xx errors
   - **Data transfer** - Bytes downloaded

### Common Issues

**Images not loading:**
- Verify S3 bucket policy allows CloudFront access
- Check distribution status is "Deployed"
- Ensure image files exist in S3 bucket
- Test CloudFront URL directly in browser

**Access Denied errors:**
- Verify OAC is properly configured
- Check S3 bucket policy has correct distribution ARN
- Ensure bucket is not blocking public access (should be blocked)

**Slow loading:**
- Check cache hit rate in CloudWatch
- Verify cache policy settings
- Consider using different price class for more edge locations

### Testing Commands

```bash
# Test image accessibility
curl -I https://<cloudfront-domain>/laptop-1.jpg

# Check cache headers
curl -H "Cache-Control: no-cache" https://<cloudfront-domain>/laptop-1.jpg -I

# Verify S3 direct access is blocked
curl -I https://<bucket-name>.s3.<region>.amazonaws.com/products/laptop-1.jpg
```

---

## Architecture Benefits

1. **Performance** - Images served from global edge locations
2. **Security** - S3 bucket is private, only accessible via CloudFront
3. **Cost optimization** - Reduced S3 data transfer costs
4. **Scalability** - CDN handles traffic spikes automatically
5. **Reliability** - Multiple edge locations provide redundancy

## Cost Estimate

For 10,000 image requests/month:
- **CloudFront:** ~$1.00 (data transfer + requests)
- **S3 storage:** ~$0.50 (for 10GB of images)
- **S3 requests:** ~$0.10 (GET requests from CloudFront)

**Total: ~$1.60/month**

## Next Steps

Your images are now served through CloudFront! Consider:
- Setting up custom domain for CloudFront (requires Route53/ACM)
- Implementing image optimization (WebP format, responsive images)
- Adding image upload functionality to admin interface

Proceed to **[Module 10: Cleanup](./module10-cleanup.md)** when ready to clean up resources.
