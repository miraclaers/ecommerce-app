#!/bin/bash

REGION="ap-south-1"
TABLE="ecommerce-products"
BUCKET="chetan-future-store"

echo "Updating product images in DynamoDB..."

jq -c '.[]' products.json | while read -r product; do
    product_id=$(echo $product | jq -r '.product_id')
    image_url="https://${BUCKET}.s3.${REGION}.amazonaws.com/images/products/${product_id}.jpg"
    
    echo "Updating $product_id..."
    
    aws dynamodb update-item \
        --table-name $TABLE \
        --key "{\"product_id\": {\"S\": \"$product_id\"}}" \
        --update-expression "SET image_url = :url" \
        --expression-attribute-values "{\":url\": {\"S\": \"$image_url\"}}" \
        --region $REGION \
        --no-cli-pager > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo "  ✓ Updated"
    else
        echo "  ✗ Failed"
    fi
done

echo "✅ Image URLs updated in DynamoDB"
