# Local Product Data Setup

This directory contains product data and images for local development.

## Files

- `products-local.json` - Product data with local image paths
- `product-images/` - Product images (prod-001.jpg to prod-020.jpg)
- `load-products-local.sh` - Script to load products into LocalStack DynamoDB

## Usage

### Load Products into LocalStack

Make sure your LocalStack containers are running, then:

```bash
./load-products-local.sh
```

This will load all 20 products into the LocalStack DynamoDB `products` table.

### Verify Products

```bash
aws dynamodb scan \
  --table-name products \
  --endpoint-url http://localhost:4566 \
  --region us-east-1 \
  --query 'Count'
```

## Image Serving

Product images are served locally from the `product-images/` directory. The frontend should be configured to serve these images from a local path (e.g., `/images/`).

To serve images, you can either:
1. Copy images to the frontend's public directory
2. Configure nginx to serve images from this directory
3. Use a simple HTTP server

Example with nginx - add to nginx.conf:
```nginx
location /images/ {
    alias /path/to/local-deployment/data/product-images/;
}
```
