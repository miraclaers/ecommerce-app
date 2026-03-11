#!/bin/bash

# Exit on any error
set -e

# Load products into LocalStack DynamoDB
# Usage: ./load-products-local.sh <region>
# Example: ./load-products-local.sh us-east-1

if [ $# -eq 0 ]; then
    echo "Error: Region parameter is required"
    echo "Usage: ./load-products-local.sh <region>"
    echo "Example: ./load-products-local.sh us-east-1"
    exit 1
fi

TABLE_NAME="ecommerce-products"
ENDPOINT="http://localhost:4566"
REGION="$1"

echo "Loading products into LocalStack DynamoDB"
echo "Table: $TABLE_NAME"
echo "Endpoint: $ENDPOINT"
echo "Region: $REGION"
echo ""

# Check if LocalStack is running
echo "Checking if LocalStack is running..."
if ! curl -s "$ENDPOINT" > /dev/null 2>&1; then
    echo "Error: LocalStack is not running or not accessible at $ENDPOINT"
    echo "Please start LocalStack with: docker compose up -d"
    exit 1
fi

# Check if table exists, create if it doesn't
echo "Checking if products table exists..."
if ! aws dynamodb describe-table --table-name "$TABLE_NAME" --endpoint-url "$ENDPOINT" --region "$REGION" > /dev/null 2>&1; then
    echo "Table $TABLE_NAME does not exist. Creating..."
    aws dynamodb create-table \
        --table-name "$TABLE_NAME" \
        --attribute-definitions AttributeName=product_id,AttributeType=S \
        --key-schema AttributeName=product_id,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --endpoint-url "$ENDPOINT" \
        --region "$REGION" > /dev/null
    
    echo "Table $TABLE_NAME created successfully"
    sleep 2
else
    echo "Table $TABLE_NAME already exists"
fi
echo ""

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed or not in PATH"
    echo "Please install AWS CLI first"
    exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed."
    echo "Install with: sudo apt-get install jq"
    exit 1
fi

# Read products from JSON file
PRODUCTS_FILE="$(dirname "$0")/products-local.json"

if [ ! -f "$PRODUCTS_FILE" ]; then
    echo "Error: products-local.json not found"
    exit 1
fi

# Count total products
TOTAL=$(jq length "$PRODUCTS_FILE")
echo "Found $TOTAL products to load"
echo ""

# Load each product
COUNTER=0
jq -c '.[]' "$PRODUCTS_FILE" | while read -r product; do
    COUNTER=$((COUNTER + 1))
    
    PRODUCT_ID=$(echo "$product" | jq -r '.product_id')
    NAME=$(echo "$product" | jq -r '.name')
    
    echo "[$COUNTER/$TOTAL] Loading: $NAME ($PRODUCT_ID)"
    
    # Convert JSON to DynamoDB format
    ITEM=$(echo "$product" | jq '{
        product_id: {S: .product_id},
        name: {S: .name},
        description: {S: .description},
        price: {N: (.price | tostring)},
        stock: {N: (.stock | tostring)},
        category: {S: .category},
        image_url: {S: .image_url}
    }')
    
    # Put item into DynamoDB
    aws dynamodb put-item \
        --table-name "$TABLE_NAME" \
        --item "$ITEM" \
        --region "$REGION" \
        --endpoint-url "$ENDPOINT" \
        > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo "  ✓ Success"
    else
        echo "  ✗ Failed"
    fi
done

echo ""
echo "Loading complete!"
echo ""
echo "Verify with:"
echo "aws dynamodb scan --table-name $TABLE_NAME --endpoint-url $ENDPOINT --region $REGION --query 'Count'"
