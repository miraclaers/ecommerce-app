# Product Data

This directory contains sample product data and images for the ecommerce application.

## Files

- **products.json** - 20 sample products with details
- **load-products.sh** - Script to load products into DynamoDB
- **download-product-images.sh** - Download sample product images
- **upload-images-to-s3.sh** - Upload images to S3 bucket
- **update-product-image-urls.sh** - Update products.json with S3 URLs

## Quick Start

### 1. Download Product Images

```bash
cd data
./download-product-images.sh
```

This downloads 20 product images (800x800px) from Unsplash into `product-images/` directory.

### 2. Upload Images to S3

```bash
./upload-images-to-s3.sh ecommerce-product-images-<your-id> ap-south-1
```

This uploads all images to `s3://bucket-name/images/products/` with public-read access.

### 3. Update Product Data with S3 URLs

```bash
./update-product-image-urls.sh ecommerce-product-images-<your-id> ap-south-1
```

This updates `products.json` to use S3 image URLs instead of Unsplash URLs.

### 4. Load Products into DynamoDB

```bash
./load-products.sh ecommerce-products <your-region>
```

This loads all 20 products with S3 image URLs into DynamoDB.

## S3 Folder Structure

```
s3://ecommerce-product-images-<id>/
└── images/
    └── products/
        ├── prod-001.jpg
        ├── prod-002.jpg
        ├── ...
        └── prod-020.jpg
```

This structure allows you to add other image types later:
- `images/products/` - Product images
- `images/banners/` - Homepage banners (future)
- `images/categories/` - Category images (future)
- `images/users/` - User avatars (future)

## Image URLs

After uploading to S3, images will be accessible at:

**Direct S3 URL:**
```
https://ecommerce-product-images-<id>.s3.ap-south-1.amazonaws.com/images/products/prod-001.jpg
```

**Via CloudFront (after Module 7):**
```
https://<cloudfront-domain>/images/products/prod-001.jpg
```

## Product Categories

- Electronics (14 products)
- Accessories (5 products)
- Furniture (1 product)

## Product Data Structure

Each product contains:
- `product_id` - Unique identifier (e.g., "prod-001")
- `name` - Product name
- `description` - Product description
- `price` - Price in USD (decimal)
- `stock` - Available quantity (integer)
- `category` - Product category
- `image_url` - S3 image URL

## Image Specifications

- Format: JPEG
- Size: 800x800px (optimized for web)
- Quality: 80%
- Source: Unsplash (free stock photos)

## Customization

### Add More Products

1. Add product data to `products.json`
2. Download/create image as `prod-0XX.jpg`
3. Place in `product-images/` directory
4. Run upload script

### Use Your Own Images

1. Replace images in `product-images/` directory
2. Keep naming convention: `prod-001.jpg`, `prod-002.jpg`, etc.
3. Run upload script

## Sample Products

1. Wireless Bluetooth Headphones - $89.99
2. Smart Watch Series 5 - $299.99
3. Mechanical Gaming Keyboard - $129.99
4. 4K Webcam - $79.99
5. Wireless Gaming Mouse - $59.99
6. USB-C Hub 7-in-1 - $39.99
7. Portable SSD 1TB - $119.99
8. Laptop Stand Aluminum - $34.99
9. Wireless Charging Pad - $24.99
10. Bluetooth Speaker Portable - $49.99
11. HD Monitor 27-inch - $189.99
12. Desk Lamp LED - $29.99
13. Laptop Backpack - $44.99
14. Microphone USB Condenser - $69.99
15. Cable Management Kit - $19.99
16. Ergonomic Office Chair - $249.99
17. Ring Light 10-inch - $39.99
18. Power Bank 20000mAh - $34.99
19. HDMI Cable 6ft - $14.99
20. Webcam Privacy Cover - $9.99

**Total Inventory Value:** ~$1,800  
**Average Price:** $75.99  
**Total Stock:** 4,675 units

## Troubleshooting

### Images not downloading
- Check internet connection
- Unsplash URLs may change - update script if needed

### S3 upload fails
- Verify AWS CLI is configured: `aws configure list`
- Check bucket exists: `aws s3 ls s3://bucket-name`
- Verify bucket permissions

### Images not public
- Check bucket policy allows public read
- Verify `--acl public-read` in upload script
- Test URL in browser

## Cost Considerations

- S3 Storage: $0.023/GB (~$0.05/month for 20 images)
- S3 Requests: Negligible for low traffic
- Data Transfer: First 100GB/month free
- Total: < $1/month for this tutorial
