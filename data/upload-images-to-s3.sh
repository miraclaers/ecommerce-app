#!/bin/bash

# Upload product images to S3 bucket
# Usage: ./upload-images-to-s3.sh <bucket-name> [region]

BUCKET_NAME=$1
REGION=${2:-ap-south-1}
IMAGES_DIR="product-images"
S3_PREFIX="images/products"

if [ -z "$BUCKET_NAME" ]; then
    echo "Error: Bucket name is required"
    echo "Usage: ./upload-images-to-s3.sh <bucket-name> [region]"
    echo "Example: ./upload-images-to-s3.sh ecommerce-product-images-12345 ap-south-1"
    exit 1
fi

if [ ! -d "$IMAGES_DIR" ]; then
    echo "Error: $IMAGES_DIR directory not found"
    echo "Run ./download-product-images.sh first to download images"
    exit 1
fi

echo "Uploading product images to S3..."
echo "Bucket: $BUCKET_NAME"
echo "Region: $REGION"
echo "S3 Path: s3://$BUCKET_NAME/$S3_PREFIX/"
echo ""

# Count images
IMAGE_COUNT=$(ls -1 "$IMAGES_DIR"/*.jpg 2>/dev/null | wc -l)
if [ "$IMAGE_COUNT" -eq 0 ]; then
    echo "Error: No images found in $IMAGES_DIR/"
    exit 1
fi

echo "Found $IMAGE_COUNT images to upload"
echo ""

# Upload images with progress
COUNTER=0
for image in "$IMAGES_DIR"/*.jpg; do
    COUNTER=$((COUNTER + 1))
    FILENAME=$(basename "$image")
    
    echo "[$COUNTER/$IMAGE_COUNT] Uploading: $FILENAME"
    
    aws s3 cp "$image" \
        "s3://$BUCKET_NAME/$S3_PREFIX/$FILENAME" \
        --region "$REGION" \
        --content-type "image/jpeg" \
        --acl public-read
    
    if [ $? -eq 0 ]; then
        echo "  ✓ Success"
    else
        echo "  ✗ Failed"
    fi
    echo ""
done

echo "Upload complete!"
echo ""
echo "Image URLs will be in format:"
echo "https://$BUCKET_NAME.s3.$REGION.amazonaws.com/$S3_PREFIX/prod-001.jpg"
echo ""
echo "Or via CloudFront (after Module 7):"
echo "https://<cloudfront-domain>/$S3_PREFIX/prod-001.jpg"
echo ""
echo "Next step: Update products.json with S3 image URLs"
