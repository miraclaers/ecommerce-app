#!/bin/bash

# Download sample product images from Unsplash
# These are placeholder images - replace with actual product images

IMAGES_DIR="product-images"

echo "Creating images directory..."
mkdir -p "$IMAGES_DIR"

echo "Downloading sample product images..."

# Product 1 - Headphones
curl -L "https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=800&q=80" -o "$IMAGES_DIR/prod-001.jpg"

# Product 2 - Smart Watch
curl -L "https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=800&q=80" -o "$IMAGES_DIR/prod-002.jpg"

# Product 3 - Keyboard
curl -L "https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=800&q=80" -o "$IMAGES_DIR/prod-003.jpg"

# Product 4 - Webcam
curl -L "https://images.unsplash.com/photo-1588508065123-287b28e013da?w=800&q=80" -o "$IMAGES_DIR/prod-004.jpg"

# Product 5 - Mouse
curl -L "https://images.unsplash.com/photo-1527814050087-3793815479db?w=800&q=80" -o "$IMAGES_DIR/prod-005.jpg"

# Product 6 - USB Hub
curl -L "https://images.unsplash.com/photo-1625948515291-69613efd103f?w=800&q=80" -o "$IMAGES_DIR/prod-006.jpg"

# Product 7 - SSD
curl -L "https://images.unsplash.com/photo-1597872200969-2b65d56bd16b?w=800&q=80" -o "$IMAGES_DIR/prod-007.jpg"

# Product 8 - Laptop Stand
curl -L "https://images.unsplash.com/photo-1527864550417-7fd91fc51a46?w=800&q=80" -o "$IMAGES_DIR/prod-008.jpg"

# Product 9 - Wireless Charger
curl -L "https://images.unsplash.com/photo-1591290619762-c588f0e8e23f?w=800&q=80" -o "$IMAGES_DIR/prod-009.jpg"

# Product 10 - Bluetooth Speaker
curl -L "https://images.unsplash.com/photo-1608043152269-423dbba4e7e1?w=800&q=80" -o "$IMAGES_DIR/prod-010.jpg"

# Product 11 - Monitor
curl -L "https://images.unsplash.com/photo-1527443224154-c4a3942d3acf?w=800&q=80" -o "$IMAGES_DIR/prod-011.jpg"

# Product 12 - Desk Lamp
curl -L "https://images.unsplash.com/photo-1507473885765-e6ed057f782c?w=800&q=80" -o "$IMAGES_DIR/prod-012.jpg"

# Product 13 - Backpack
curl -L "https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=800&q=80" -o "$IMAGES_DIR/prod-013.jpg"

# Product 14 - Microphone
curl -L "https://images.unsplash.com/photo-1590602847861-f357a9332bbc?w=800&q=80" -o "$IMAGES_DIR/prod-014.jpg"

# Product 15 - Cable Management
curl -L "https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800&q=80" -o "$IMAGES_DIR/prod-015.jpg"

# Product 16 - Office Chair
curl -L "https://images.unsplash.com/photo-1580480055273-228ff5388ef8?w=800&q=80" -o "$IMAGES_DIR/prod-016.jpg"

# Product 17 - Ring Light
curl -L "https://images.unsplash.com/photo-1611532736597-de2d4265fba3?w=800&q=80" -o "$IMAGES_DIR/prod-017.jpg"

# Product 18 - Power Bank
curl -L "https://images.unsplash.com/photo-1609091839311-d5365f9ff1c5?w=800&q=80" -o "$IMAGES_DIR/prod-018.jpg"

# Product 19 - HDMI Cable
curl -L "https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800&q=80" -o "$IMAGES_DIR/prod-019.jpg"

# Product 20 - Webcam Cover
curl -L "https://images.unsplash.com/photo-1550009158-9ebf69173e03?w=800&q=80" -o "$IMAGES_DIR/prod-020.jpg"

echo ""
echo "✓ Downloaded 20 product images"
echo "Images saved in: $IMAGES_DIR/"
echo ""
echo "Next step: Run upload-images-to-s3.sh to upload to S3"
