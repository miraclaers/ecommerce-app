#!/bin/bash

set -e

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: bash build-and-deploy-services.sh <account-id> <region> [service]"
  echo "Example (all):    bash build-and-deploy-services.sh 123456789012 us-west-2"
  echo "Example (single): bash build-and-deploy-services.sh 123456789012 us-west-2 order"
  exit 1
fi

ACCOUNT_ID="$1"
REGION="$2"
FILTER="$3"
ECR_REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
CLUSTER="ecommerce-cluster"

declare -A ECS_SERVICE_MAP=(
  ["product-service"]="ecommerce-product-service-service-yns95p75"
  ["cart-service"]="ecommerce-cart-service-service-4x0sxk99"
  ["user-service"]="ecommerce-user-service-service-bdm4vkrp"
  ["order-service"]="ecommerce-order-service-service-tmmtur32"
)

# Build service list
if [ -n "$FILTER" ]; then
  SERVICE_NAME="${FILTER}-service"
  if [ -z "${ECS_SERVICE_MAP[$SERVICE_NAME]}" ]; then
    echo "Error: Unknown service '$FILTER'. Valid values: product, cart, user, order"
    exit 1
  fi
  SERVICES=("$SERVICE_NAME")
else
  SERVICES=("product-service" "cart-service" "user-service" "order-service")
fi

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
for SERVICE in "${SERVICES[@]}"; do
  ECS_SERVICE="${ECS_SERVICE_MAP[$SERVICE]}"
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
