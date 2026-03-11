from fastapi import FastAPI, HTTPException, Header
from typing import Optional
from models import Cart, AddItemRequest, UpdateItemRequest
from database import get_carts_table
from datetime import datetime
from decimal import Decimal
import json
import base64

app = FastAPI(title="Cart Service")

def convert_floats_to_decimal(obj):
    """Convert float values to Decimal for DynamoDB"""
    if isinstance(obj, list):
        return [convert_floats_to_decimal(item) for item in obj]
    elif isinstance(obj, dict):
        return {k: convert_floats_to_decimal(v) for k, v in obj.items()}
    elif isinstance(obj, float):
        return Decimal(str(obj))
    return obj

def get_user_id_from_token(authorization: Optional[str]) -> str:
    """Extract user_id from JWT token. For local testing, use mock user_id"""
    if not authorization:
        return "test-user-123"
    
    try:
        token = authorization.replace("Bearer ", "")
        parts = token.split('.')
        if len(parts) != 3:
            return "test-user-123"
        
        payload = parts[1]
        payload += '=' * (4 - len(payload) % 4)
        decoded = base64.urlsafe_b64decode(payload)
        user_data = json.loads(decoded)
        
        return user_data.get('sub', 'test-user-123')
    except Exception:
        return "test-user-123"

@app.get("/health")
def health_check():
    return {"status": "healthy", "service": "cart-service"}

# Explicit OPTIONS handlers for CORS preflight
@app.options("/cart")
@app.options("/cart/items")
@app.options("/cart/items/{product_id}")
async def options_handler():
    return {}

@app.get("/cart", response_model=Cart)
def get_cart(authorization: str = Header(None), x_user_id: str = Header(None, alias="X-User-Id")):
    """Get user's cart. Supports both JWT token and X-User-Id header"""
    # Try JWT token first, fall back to X-User-Id for internal service calls
    user_id = get_user_id_from_token(authorization) if authorization else x_user_id
    if not user_id:
        user_id = "test-user-123"
    
    table = get_carts_table()
    response = table.get_item(Key={'user_id': user_id})
    
    if 'Item' not in response:
        # Return empty cart
        return Cart(user_id=user_id, items=[], updated_at=datetime.utcnow().isoformat())
    
    return response['Item']

@app.post("/cart/items")
def add_item(request: AddItemRequest, authorization: str = Header(None), x_user_id: str = Header(None, alias="X-User-Id")):
    user_id = get_user_id_from_token(authorization)
    if not user_id:
        user_id = x_user_id
    if not user_id:
        user_id = "test-user-123"
    
    table = get_carts_table()
    
    # Get current cart
    response = table.get_item(Key={'user_id': user_id})
    
    if 'Item' in response:
        items = response['Item']['items']
        # Check if product already in cart
        existing_item = next((item for item in items if item['product_id'] == request.product_id), None)
        if existing_item:
            existing_item['quantity'] += request.quantity
        else:
            items.append(convert_floats_to_decimal(request.dict()))
    else:
        items = [convert_floats_to_decimal(request.dict())]
    
    # Update cart
    table.put_item(Item={
        'user_id': user_id,
        'items': items,
        'updated_at': datetime.utcnow().isoformat()
    })
    
    return {"message": "Item added to cart", "user_id": user_id}

@app.put("/cart/items/{product_id}")
def update_item(product_id: str, request: UpdateItemRequest, authorization: str = Header(None), x_user_id: str = Header(None, alias="X-User-Id")):
    user_id = get_user_id_from_token(authorization)
    if not user_id:
        user_id = x_user_id
    if not user_id:
        user_id = "test-user-123"
    
    table = get_carts_table()
    response = table.get_item(Key={'user_id': user_id})
    
    if 'Item' not in response:
        raise HTTPException(status_code=404, detail="Cart not found")
    
    items = response['Item']['items']
    item = next((item for item in items if item['product_id'] == product_id), None)
    
    if not item:
        raise HTTPException(status_code=404, detail="Item not found in cart")
    
    item['quantity'] = request.quantity
    
    table.put_item(Item={
        'user_id': user_id,
        'items': items,
        'updated_at': datetime.utcnow().isoformat()
    })
    
    return {"message": "Item updated"}

@app.delete("/cart/items/{product_id}")
def remove_item(product_id: str, authorization: str = Header(None), x_user_id: str = Header(None, alias="X-User-Id")):
    user_id = get_user_id_from_token(authorization)
    if not user_id:
        user_id = x_user_id
    if not user_id:
        user_id = "test-user-123"
    
    table = get_carts_table()
    response = table.get_item(Key={'user_id': user_id})
    
    if 'Item' not in response:
        raise HTTPException(status_code=404, detail="Cart not found")
    
    items = [item for item in response['Item']['items'] if item['product_id'] != product_id]
    
    table.put_item(Item={
        'user_id': user_id,
        'items': items,
        'updated_at': datetime.utcnow().isoformat()
    })
    
    return {"message": "Item removed"}

@app.delete("/cart")
def clear_cart(authorization: str = Header(None), x_user_id: str = Header(None, alias="X-User-Id")):
    """Internal endpoint - called by Order Service after order creation"""
    # Try JWT token first, fall back to X-User-Id for internal service calls
    user_id = get_user_id_from_token(authorization) if authorization else x_user_id
    if not user_id:
        user_id = "test-user-123"
    
    table = get_carts_table()
    table.delete_item(Key={'user_id': user_id})
    
    return {"message": "Cart cleared"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8002)
