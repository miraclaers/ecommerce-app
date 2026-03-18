#!/bin/bash

# Update products.json with CloudFront image URLs
# Usage: ./update-product-image-urls.sh <cloudfront-base-url>
# Example: ./update-product-image-urls.sh https://d1234567890.cloudfront.net

CLOUDFRONT_URL=${1%/}  # strip trailing slash if present
IMAGE_PREFIX="images/products"
PRODUCTS_FILE="products.json"

if [ -z "$CLOUDFRONT_URL" ]; then
    echo "Error: CloudFront base URL is required"
    echo "Usage: ./update-product-image-urls.sh <cloudfront-base-url>"
    echo "Example: ./update-product-image-urls.sh https://d1234567890.cloudfront.net"
    exit 1
fi

if [ ! -f "$PRODUCTS_FILE" ]; then
    echo "Error: $PRODUCTS_FILE not found"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed."
    echo "Install with: sudo apt-get install jq (Ubuntu/Debian) or brew install jq (Mac)"
    exit 1
fi

echo "Updating product image URLs in $PRODUCTS_FILE..."
echo "CloudFront URL: $CLOUDFRONT_URL"
echo ""

cp "$PRODUCTS_FILE" "${PRODUCTS_FILE}.backup"
echo "Backup created: ${PRODUCTS_FILE}.backup"

jq --arg base "$CLOUDFRONT_URL" \
   --arg prefix "$IMAGE_PREFIX" \
   'map(.image_url = "\($base)/\($prefix)/\(.product_id).jpg")' \
   "$PRODUCTS_FILE" > "${PRODUCTS_FILE}.tmp"

mv "${PRODUCTS_FILE}.tmp" "$PRODUCTS_FILE"

echo "Updated image URLs in $PRODUCTS_FILE"
echo ""
echo "Sample URL:"
jq -r '.[0].image_url' "$PRODUCTS_FILE"
echo ""
echo "Next step: Load products into DynamoDB with ./load-products.sh <region>"
