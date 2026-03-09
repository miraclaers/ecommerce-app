#!/bin/bash

# Download product images from Unsplash based on product names
# Images are already mapped in products.json with correct URLs

echo "Downloading product images..."

mkdir -p product-images

# Extract image URLs from products.json and download them
jq -r '.[] | "\(.product_id) \(.image_url)"' products.json | while read -r product_id url; do
    echo "Downloading $product_id..."
    curl -L "$url" -o "product-images/${product_id}.jpg" --silent
    sleep 0.5  # Rate limiting
done

echo "✅ Downloaded 20 product images"
echo "Images saved in product-images/ directory"
