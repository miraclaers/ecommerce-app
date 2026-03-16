#!/usr/bin/env python3
import boto3
import sys
import json
from decimal import Decimal

def update_image_urls(region, domain_name):
    """Update DynamoDB product image URLs to use custom domain"""
    
    dynamodb = boto3.resource('dynamodb', region_name=region)
    table = dynamodb.Table('ecommerce-products')
    
    try:
        # Scan all products
        response = table.scan()
        products = response['Items']
        
        updated_count = 0
        
        for product in products:
            product_id = product['product_id']
            current_image_url = product.get('image_url', '')
            
            # Skip if already using the domain
            if domain_name in current_image_url:
                print(f"Skipping {product_id} - already using {domain_name}")
                continue
            
            # Extract filename from current URL
            if 's3.amazonaws.com' in current_image_url or 's3.' in current_image_url or 'cloudfront.net' in current_image_url:
                filename = current_image_url.split('/')[-1]
                new_image_url = f"https://{domain_name}/images/{filename}"
                
                # Update the product
                table.update_item(
                    Key={'product_id': product_id},
                    UpdateExpression='SET image_url = :url',
                    ExpressionAttributeValues={':url': new_image_url}
                )
                
                print(f"Updated {product_id}: {filename}")
                updated_count += 1
            else:
                print(f"Skipping {product_id} - URL format not recognized")
        
        print(f"\nSuccessfully updated {updated_count} products")
        
    except Exception as e:
        print(f"Error updating image URLs: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 update-image-urls-domain.py <region> <domain-name>")
        print("Example: python3 update-image-urls-domain.py us-east-1 cloud11.io")
        sys.exit(1)
    
    region = sys.argv[1]
    domain_name = sys.argv[2]
    
    print(f"Updating image URLs to use domain: {domain_name}")
    update_image_urls(region, domain_name)
