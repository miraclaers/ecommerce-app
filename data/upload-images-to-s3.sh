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

# Check AWS CLI configuration
echo "Checking AWS CLI configuration..."
if ! aws sts get-caller-identity >/dev/null 2>&1; then
    echo ""
    echo "❌ ERROR: AWS CLI is not configured or credentials are invalid"
    echo ""
    echo "Please configure AWS CLI first:"
    echo "  aws configure"
    echo ""
    echo "Or check your credentials:"
    echo "  aws sts get-caller-identity"
    echo ""
    exit 1
fi

# Check if bucket exists and is accessible
echo "Checking S3 bucket access..."
if ! aws s3 ls "s3://$BUCKET_NAME" --region "$REGION" >/dev/null 2>&1; then
    echo ""
    echo "❌ ERROR: Cannot access S3 bucket '$BUCKET_NAME'"
    echo ""
    echo "Possible issues:"
    echo "  • Bucket doesn't exist"
    echo "  • Wrong region (current: $REGION)"
    echo "  • Insufficient permissions"
    echo ""
    echo "Create bucket first:"
    echo "  aws s3 mb s3://$BUCKET_NAME --region $REGION"
    echo ""
    exit 1
fi

echo "✓ AWS CLI configured and bucket accessible"
echo ""

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

# Upload images with progress and error handling
COUNTER=0
FAILED_COUNT=0
for image in "$IMAGES_DIR"/*.jpg; do
    COUNTER=$((COUNTER + 1))
    FILENAME=$(basename "$image")
    
    echo "[$COUNTER/$IMAGE_COUNT] Uploading: $FILENAME"
    
    # Capture error output
    ERROR_OUTPUT=$(aws s3 cp "$image" \
        "s3://$BUCKET_NAME/$S3_PREFIX/$FILENAME" \
        --region "$REGION" \
        --content-type "image/jpeg" 2>&1)
    
    if [ $? -eq 0 ]; then
        echo "  ✓ Success"
    else
        echo "  ❌ Failed to upload $FILENAME"
        echo "  Error details: $ERROR_OUTPUT"
        FAILED_COUNT=$((FAILED_COUNT + 1))
        
        # Stop on first failure to avoid spamming errors
        echo ""
        echo "❌ Upload failed. Stopping to avoid further errors."
        echo ""
        echo "Common solutions:"
        echo "  • Check AWS credentials: aws sts get-caller-identity"
        echo "  • Verify bucket permissions"
        echo "  • Check internet connectivity"
        echo "  • Ensure bucket exists: aws s3 ls s3://$BUCKET_NAME"
        echo ""
        exit 1
    fi
    echo ""
done

if [ "$FAILED_COUNT" -eq 0 ]; then
    echo "✅ All uploads completed successfully!"
else
    echo "⚠️  Upload completed with $FAILED_COUNT failures"
fi

echo ""
echo "Image URLs will be in format:"
echo "https://$BUCKET_NAME.s3.$REGION.amazonaws.com/$S3_PREFIX/prod-001.jpg"
echo ""
echo "Or via CloudFront (after Module 7):"
echo "https://<cloudfront-domain>/$S3_PREFIX/prod-001.jpg"
echo ""
echo "Next step: Update products.json with S3 image URLs"
