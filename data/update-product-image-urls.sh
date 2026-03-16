#!/bin/bash

# Update products.json with S3 image URLs
# Usage: ./update-product-image-urls.sh <bucket-name> [region]

BUCKET_NAME=$1
REGION=${2:-ap-south-1}
S3_PREFIX="images/products"
PRODUCTS_FILE="products.json"

if [ -z "$BUCKET_NAME" ]; then
    echo "Error: Bucket name is required"
    echo "Usage: ./update-product-image-urls.sh <bucket-name> [region]"
    echo "Example: ./update-product-image-urls.sh ecommerce-product-images-12345 ap-south-1"
    exit 1
fi

if [ ! -f "$PRODUCTS_FILE" ]; then
    echo "Error: $PRODUCTS_FILE not found"
    exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed."
    echo "Install with: sudo apt-get install jq (Ubuntu/Debian) or brew install jq (Mac)"
    exit 1
fi

echo "Updating product image URLs in $PRODUCTS_FILE..."
echo "S3 Bucket: $BUCKET_NAME"
echo "Region: $REGION"
echo ""

# Backup original file
cp "$PRODUCTS_FILE" "${PRODUCTS_FILE}.backup"
echo "✓ Backup created: ${PRODUCTS_FILE}.backup"

# Update image URLs
jq --arg bucket "$BUCKET_NAME" \
   --arg region "$REGION" \
   --arg prefix "$S3_PREFIX" \
   'map(
     .image_url = "https://\($bucket).s3.\($region).amazonaws.com/\($prefix)/\(.product_id).jpg"
   )' "$PRODUCTS_FILE" > "${PRODUCTS_FILE}.tmp"

# Replace original file
mv "${PRODUCTS_FILE}.tmp" "$PRODUCTS_FILE"

echo "✓ Updated image URLs in $PRODUCTS_FILE"
echo ""
echo "Sample URL:"
jq -r '.[0].image_url' "$PRODUCTS_FILE"
echo ""
echo "Next step: Load products into DynamoDB with ./load-products.sh <table-name> <region>"
