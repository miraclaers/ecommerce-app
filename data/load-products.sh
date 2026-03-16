#!/bin/bash

# Load products into DynamoDB
# Usage: ./load-products.sh <region>

TABLE_NAME="ecommerce-products"
REGION=$1

if [ -z "$REGION" ]; then
    echo "Error: Region is required"
    echo "Usage: ./load-products.sh <region>"
    echo "Example: ./load-products.sh us-east-1"
    exit 1
fi

echo "Loading products into DynamoDB table: $TABLE_NAME"
echo "Region: $REGION"
echo ""

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed."
    echo "Install with: sudo apt-get install jq (Ubuntu/Debian) or brew install jq (Mac)"
    exit 1
fi

# Check if table exists, create if not
echo "Checking if table $TABLE_NAME exists..."
if ! aws dynamodb describe-table --table-name "$TABLE_NAME" --region "$REGION" > /dev/null 2>&1; then
    echo "Table $TABLE_NAME does not exist. Creating..."
    
    aws dynamodb create-table \
        --table-name "$TABLE_NAME" \
        --attribute-definitions AttributeName=product_id,AttributeType=S \
        --key-schema AttributeName=product_id,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region "$REGION"
    
    if [ $? -eq 0 ]; then
        echo "✓ Table created successfully"
        echo "Waiting for table to become active..."
        aws dynamodb wait table-exists --table-name "$TABLE_NAME" --region "$REGION"
        echo "✓ Table is now active"
    else
        echo "✗ Failed to create table"
        exit 1
    fi
else
    echo "✓ Table $TABLE_NAME already exists"
fi

# Also check/create carts table if it doesn't exist
CARTS_TABLE="ecommerce-cart"
echo "Checking if table $CARTS_TABLE exists..."
if ! aws dynamodb describe-table --table-name "$CARTS_TABLE" --region "$REGION" > /dev/null 2>&1; then
    echo "Table $CARTS_TABLE does not exist. Creating..."
    
    aws dynamodb create-table \
        --table-name "$CARTS_TABLE" \
        --attribute-definitions AttributeName=user_id,AttributeType=S \
        --key-schema AttributeName=user_id,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region "$REGION"
    
    if [ $? -eq 0 ]; then
        echo "✓ Carts table created successfully"
        echo "Waiting for carts table to become active..."
        aws dynamodb wait table-exists --table-name "$CARTS_TABLE" --region "$REGION"
        echo "✓ Carts table is now active"
    else
        echo "✗ Failed to create carts table"
        exit 1
    fi
else
    echo "✓ Table $CARTS_TABLE already exists"
fi
echo ""

# Read products from JSON file
PRODUCTS_FILE="$(dirname "$0")/products.json"

if [ ! -f "$PRODUCTS_FILE" ]; then
    echo "Error: products.json not found at $PRODUCTS_FILE"
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
    
    # Extract product details for display
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
    
    # Put item into DynamoDB and capture output
    ERROR_OUTPUT=$(aws dynamodb put-item \
        --table-name "$TABLE_NAME" \
        --item "$ITEM" \
        --region "$REGION" 2>&1)
    
    if [ $? -eq 0 ]; then
        echo "  ✓ Success"
    else
        echo "  ✗ Failed"
        echo "  Error details: $ERROR_OUTPUT"
        echo ""
        echo "❌ Loading failed. Stopping to avoid further errors."
        echo ""
        echo "Common solutions:"
        echo "  • Check AWS credentials: aws sts get-caller-identity"
        echo "  • Verify table exists: aws dynamodb describe-table --table-name $TABLE_NAME --region $REGION"
        echo "  • Check permissions for DynamoDB"
        echo ""
        exit 1
    fi
    echo ""
done

echo "Loading complete!"
echo ""
echo "Verify with:"
echo "aws dynamodb scan --table-name $TABLE_NAME --region $REGION --query 'Count'"
