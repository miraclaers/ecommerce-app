# Module 9: Image CDN with Existing CloudFront

## Overview

This module adds product images to your existing CloudFront distribution by creating a second origin for the images bucket and configuring path-based routing.

### Architecture

```
Frontend → CloudFront Distribution → Origin 1: S3 Frontend Bucket (/)
                                  → Origin 2: S3 Images Bucket (/images/*)
```

### What You'll Build

- **Reuse existing CloudFront** distribution from Module 6
- **Add images bucket** as second origin
- **Configure path routing** - `/images/*` routes to images bucket
- **Make images bucket private** with OAC
- **Update DynamoDB URLs** to use your custom domain

### Benefits

- **Simple setup** - Reuse existing infrastructure
- **Single domain** - All content served from your domain (e.g., `https://cloud11.io`)
- **Cost effective** - No additional CloudFront distribution
- **Consistent** - Frontend and images from same domain

---

## 9.1 Make Images Bucket Private

### Update Bucket Permissions

1. **Go to your existing images S3 bucket** (created in Module 2)
2. **Permissions → Block public access → Edit**
3. **Enable all blocks:**
   - ✅ Block all public access
   - ✅ Block public access to buckets and objects granted through new access control lists (ACLs)
   - ✅ Block public access to buckets and objects granted through any access control lists (ACLs)
   - ✅ Block public access to buckets and objects granted through new public bucket or access point policies
   - ✅ Block public access to buckets and objects granted through any public bucket or access point policies
4. **Save changes**

### Remove Public Bucket Policy

5. **Permissions → Bucket policy**
6. **Delete existing policy** (if any)
7. **Save changes**

---

## 9.2 Add Images Origin to CloudFront

### Add New Origin

1. **CloudFront Console → Your distribution → Origins → Create origin**
2. **Origin domain:** Select your images S3 bucket
3. **Origin path:** `/products` (if images are in products folder)
4. **Name:** `images-origin`
5. **Origin access:** Origin access control settings
6. **Origin access control:** Create new OAC
   - **Name:** `images-oac`
   - **Description:** `OAC for product images`
   - **Origin type:** S3
   - **Create**
7. **Create origin**

### Create Cache Behavior for Images

8. **Behaviors → Create behavior**
9. **Path pattern:** `/images/*`
10. **Origin:** Select `images-origin`
11. **Viewer protocol policy:** Redirect HTTP to HTTPS
12. **Allowed HTTP methods:** GET, HEAD
13. **Cache policy:** Managed-CachingOptimized
14. **Create behavior**

### Update S3 Bucket Policy

15. **CloudFront will show banner** "Update S3 bucket policy"
16. **Copy the policy** and apply to images bucket
17. **Or create manually:**

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
      "Resource": "arn:aws:s3:::your-images-bucket/*",
      "Condition": {
        "StringEquals": {
          "AWS:SourceArn": "arn:aws:cloudfront::<account-id>:distribution/<distribution-id>"
        }
      }
    }
  ]
}
```

18. **Wait for deployment** (5-10 minutes)

---

## 9.3 Test Image Access

### Test CloudFront Image URLs

1. **Get image filename** from S3 bucket:
   ```bash
   aws s3 ls s3://your-images-bucket/products/
   ```

2. **Test new CloudFront path:**
   ```
   https://your-domain.com/images/laptop-1.jpg
   ```

3. **Verify image loads** in browser

### Test S3 Direct Access (Should Fail)

4. **Try direct S3 URL** (should return Access Denied):
   ```
   https://your-images-bucket.s3.region.amazonaws.com/products/laptop-1.jpg
   ```

---

## 9.4 Update DynamoDB Image URLs

### Create Update Script

1. **Create script:** `data/update-image-urls-domain.py`

```python
#!/usr/bin/env python3
import boto3
import sys
import json
from decimal import Decimal

def update_image_urls(region, domain_name):
    """Update DynamoDB product image URLs to use custom domain"""
    
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
            
            # Skip if already using the domain
            if domain_name in current_image_url:
                print(f"Skipping {product_id} - already using {domain_name}")
                continue
            
            # Extract filename from current URL
            if 's3.amazonaws.com' in current_image_url or 's3.' in current_image_url or 'cloudfront.net' in current_image_url:
                filename = current_image_url.split('/')[-1]
                new_image_url = f"https://{domain_name}/images/{filename}"
                
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
        print("Usage: python3 update-image-urls-domain.py <region> <domain-name>")
        print("Example: python3 update-image-urls-domain.py us-east-1 cloud11.io")
        sys.exit(1)
    
    region = sys.argv[1]
    domain_name = sys.argv[2]
    
    print(f"Updating image URLs to use domain: {domain_name}")
    update_image_urls(region, domain_name)
```

2. **Make script executable:**
   ```bash
   chmod +x data/update-image-urls-domain.py
   ```

### Run Update Script

3. **Update DynamoDB with your domain:**
   ```bash
   cd data
   python3 update-image-urls-domain.py <your-region> <your-domain>
   ```
   
   Example:
   ```bash
   python3 update-image-urls-domain.py us-east-1 cloud11.io
   ```

### Verify Updates

4. **Check updated URLs:**
   ```bash
   aws dynamodb scan \
     --table-name ecommerce-products \
     --projection-expression "product_id, image_url" \
     --region <your-region>
   ```

5. **Test frontend** - Product images should now load from `https://your-domain.com/images/`

---

## 9.5 Troubleshooting

### Images not loading

**Check CloudFront behavior:**
- Verify `/images/*` path pattern exists
- Ensure behavior points to images origin
- Check distribution status is "Deployed"

**Check S3 bucket policy:**
- Verify OAC policy is applied to images bucket
- Ensure bucket blocks all public access
- Check policy has correct distribution ARN

**Test direct paths:**
```bash
# Should work
curl -I https://your-domain.com/images/laptop-1.jpg

# Should fail (Access Denied)
curl -I https://your-images-bucket.s3.region.amazonaws.com/products/laptop-1.jpg
```

### DynamoDB update issues

**Check script parameters:**
- Verify region is correct
- Ensure domain name doesn't include https://
- Check DynamoDB table exists and is accessible

**Manual verification:**
```bash
# Check current URLs
aws dynamodb get-item \
  --table-name ecommerce-products \
  --key '{"product_id":{"S":"1"}}' \
  --region <your-region>
```

---

## Architecture Benefits

1. **Simplified** - Reuse existing CloudFront distribution
2. **Cost effective** - No additional CloudFront costs
3. **Consistent** - Single domain for all content
4. **Secure** - Private S3 bucket with OAC
5. **Performance** - Global CDN for images
6. **Maintainable** - Fewer resources to manage

## Cost Impact

**Additional costs:** ~$0.01-0.05/month
- Only S3 storage and minimal CloudFront requests
- Reuses existing CloudFront distribution

## Next Steps

Your images are now served through your custom domain! The complete flow:
- Frontend: `https://your-domain.com/` → S3 frontend bucket
- Images: `https://your-domain.com/images/` → S3 images bucket
- Both secured with OAC and served globally via CloudFront

Proceed to **[Module 10: Cleanup](./module10-cleanup.md)** when ready to clean up resources.
