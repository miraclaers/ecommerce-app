#!/bin/bash

set -e

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: bash build-and-deploy-services.sh <account-id> <region>"
  echo "Example: bash build-and-deploy-services.sh 123456789012 us-west-2"
  exit 1
fi

ACCOUNT_ID="$1"
REGION="$2"
ECR_REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
CLUSTER="ecommerce-cluster"

SERVICES=("product-service" "cart-service" "user-service" "order-service")

ECS_SERVICE_NAMES=(
  "ecommerce-product-service-service-yns95p75"
  "ecommerce-cart-service-service-4x0sxk99"
  "ecommerce-user-service-service-bdm4vkrp"
  "ecommerce-order-service-service-tmmtur32"
)

# ECR login
echo "Logging in to ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_REGISTRY

# Build, tag, push
for SERVICE in "${SERVICES[@]}"; do
  echo ""
  echo "==> Building $SERVICE..."
  docker build -t ecommerce/$SERVICE services/$SERVICE

  echo "==> Tagging $SERVICE..."
  docker tag ecommerce/$SERVICE:latest $ECR_REGISTRY/ecommerce/$SERVICE:latest

  echo "==> Pushing $SERVICE..."
  docker push $ECR_REGISTRY/ecommerce/$SERVICE:latest
done

# Force new ECS deployments
echo ""
echo "==> Updating ECS services..."
for ECS_SERVICE in "${ECS_SERVICE_NAMES[@]}"; do
  echo "Updating $ECS_SERVICE..."
  aws ecs update-service \
    --cluster $CLUSTER \
    --service $ECS_SERVICE \
    --force-new-deployment \
    --region $REGION \
    --query 'service.serviceName' \
    --output text
done

echo ""
echo "Done. New deployments triggered for all services."
