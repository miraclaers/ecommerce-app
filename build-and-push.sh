#!/bin/bash

# Configuration
AWS_REGION="ap-south-1"
AWS_ACCOUNT_ID="387258180757"
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# Services to build
SERVICES=("product-service" "cart-service" "user-service" "order-service")

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}Starting build and push process...${NC}\n"

# Login to ECR
echo -e "${BLUE}Logging in to ECR...${NC}"
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to login to ECR${NC}"
    exit 1
fi

# Build and push each service
for SERVICE in "${SERVICES[@]}"; do
    echo -e "\n${GREEN}Building $SERVICE...${NC}"
    
    cd services/$SERVICE
    
    # Build image
    docker build -t $SERVICE:latest .
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to build $SERVICE${NC}"
        cd ../..
        continue
    fi
    
    # Tag image
    docker tag $SERVICE:latest $ECR_REGISTRY/$SERVICE:latest
    
    # Push image
    echo -e "${BLUE}Pushing $SERVICE to ECR...${NC}"
    docker push $ECR_REGISTRY/$SERVICE:latest
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Successfully pushed $SERVICE${NC}"
    else
        echo -e "${RED}✗ Failed to push $SERVICE${NC}"
    fi
    
    cd ../..
done

echo -e "\n${GREEN}Build and push complete!${NC}"
echo -e "${BLUE}Next: Force new deployment in ECS to use updated images${NC}"
