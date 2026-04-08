# Module 10: Cleanup

## Overview
Clean up all AWS resources created during this project to avoid ongoing charges.

## Cleanup Order

Delete resources in reverse order of creation to avoid dependency issues:

### 1. DNS & SSL (Module 9)
- Route53 DNS records (A records, CNAME records)
- ACM SSL certificate
- Route53 Public hosted zone

### 2. Notification (Module 8)
- SNS subscriptions (email, SQS)
- SQS queue
- SNS topic

### 3. API Gateway (Module 6)
- API Gateway HTTP API
- VPC Link
- JWT Authorizer

### 4. Container Deployment (Module 5)
- ECS services
- ECS cluster
- ECS task definitions
- ECR repositories
- Application Load Balancer
- Target groups
- IAM role (ECS task role)
- Security group (ECS tasks)

### 5. Data Layer (Module 4)
- RDS database instance
- DB subnet group
- Security group (RDS)
- DynamoDB tables (products, cart)
- Parameter Store parameters

### 6. Frontend Infrastructure (Module 3)
- CloudFront distribution (frontend)
- S3 bucket (frontend)

### 7. Authentication (Module 2)
- Cognito User Pool
- Cognito App Client

### 8. Networking (Module 1)
- NAT Gateway
- Release NAT Gateway Elastic IP
- Delete VPC
- Security groups (ALB)
- VPC

<details>
<summary><strong>CLI equivalent - Full Cleanup</strong></summary>

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=$(aws configure get region)

# ── Module 8: Notification ──────────────────────────────────────────────────

SNS_TOPIC_ARN=$(aws sns list-topics \
  --query "Topics[?ends_with(TopicArn, ':ecommerce-order-events')].TopicArn" --output text)

# Delete all subscriptions
for SUB_ARN in $(aws sns list-subscriptions-by-topic --topic-arn $SNS_TOPIC_ARN \
  --query 'Subscriptions[*].SubscriptionArn' --output text); do
  aws sns unsubscribe --subscription-arn $SUB_ARN && echo "Unsubscribed: $SUB_ARN"
done

aws sns delete-topic --topic-arn $SNS_TOPIC_ARN && echo "Deleted SNS topic"

SQS_QUEUE_URL=$(aws sqs get-queue-url --queue-name ecommerce-order-shipping \
  --query 'QueueUrl' --output text)
aws sqs delete-queue --queue-url $SQS_QUEUE_URL && echo "Deleted SQS queue"

# ── Module 6: API Gateway ────────────────────────────────────────────────────

API_ID=$(aws apigatewayv2 get-apis \
  --query 'Items[?Name==`ecommerce-api`].ApiId' --output text)
aws apigatewayv2 delete-api --api-id $API_ID && echo "Deleted API Gateway"

VPC_LINK_ID=$(aws apigatewayv2 get-vpc-links \
  --query 'Items[?Name==`ecommerce-vpc-link`].VpcLinkId' --output text)
aws apigatewayv2 delete-vpc-link --vpc-link-id $VPC_LINK_ID && echo "Deleted VPC Link"

# ── Module 5: ECS / ECR / ALB ────────────────────────────────────────────────

for SVC in product-service cart-service user-service order-service; do
  aws ecs update-service --cluster ecommerce-cluster \
    --service ecommerce-$SVC --desired-count 0 > /dev/null
  aws ecs delete-service --cluster ecommerce-cluster \
    --service ecommerce-$SVC --force > /dev/null && echo "Deleted ECS service: $SVC"
done

aws ecs delete-cluster --cluster ecommerce-cluster > /dev/null && echo "Deleted ECS cluster"

for SVC in product-service cart-service user-service order-service; do
  REVISIONS=$(aws ecs list-task-definitions \
    --family-prefix ecommerce-$SVC --query 'taskDefinitionArns' --output text)
  for REV in $REVISIONS; do
    aws ecs deregister-task-definition --task-definition $REV > /dev/null
  done
  echo "Deregistered task definitions: $SVC"
done

for SVC in product-service cart-service user-service order-service; do
  aws ecr delete-repository \
    --repository-name ecommerce/$SVC --force > /dev/null && echo "Deleted ECR repo: $SVC"
done

ALB_ARN=$(aws elbv2 describe-load-balancers --names ecommerce-internal-alb \
  --query 'LoadBalancers[0].LoadBalancerArn' --output text)

LISTENER_ARN=$(aws elbv2 describe-listeners --load-balancer-arn $ALB_ARN \
  --query 'Listeners[0].ListenerArn' --output text)
aws elbv2 delete-listener --listener-arn $LISTENER_ARN > /dev/null

aws elbv2 delete-load-balancer --load-balancer-arn $ALB_ARN > /dev/null && echo "Deleted ALB"

for TG in product-service-tg cart-service-tg user-service-tg order-service-tg; do
  TG_ARN=$(aws elbv2 describe-target-groups --names $TG \
    --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null)
  [ -n "$TG_ARN" ] && aws elbv2 delete-target-group \
    --target-group-arn $TG_ARN > /dev/null && echo "Deleted target group: $TG"
done

aws iam detach-role-policy \
  --role-name ecommerce-ecs-task-role \
  --policy-arn arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess
aws iam detach-role-policy \
  --role-name ecommerce-ecs-task-role \
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess
aws iam detach-role-policy \
  --role-name ecommerce-ecs-task-role \
  --policy-arn arn:aws:iam::aws:policy/AmazonSNSFullAccess
aws iam delete-role --role-name ecommerce-ecs-task-role && echo "Deleted ECS task role"

# ── Module 4: Data Layer ─────────────────────────────────────────────────────

aws rds delete-db-instance \
  --db-instance-identifier ecommercedb-instance \
  --skip-final-snapshot > /dev/null
echo "Deleting RDS instance (this takes a few minutes)..."
aws rds wait db-instance-deleted --db-instance-identifier ecommercedb-instance
echo "RDS instance deleted"

aws rds delete-db-subnet-group \
  --db-subnet-group-name ecommerce-db-subnet-group && echo "Deleted DB subnet group"

aws dynamodb delete-table --table-name ecommerce-products > /dev/null && echo "Deleted DynamoDB: ecommerce-products"
aws dynamodb delete-table --table-name ecommerce-cart > /dev/null && echo "Deleted DynamoDB: ecommerce-cart"

for PARAM in /ecommerce/dev/aws/region /ecommerce/dev/db/host /ecommerce/dev/db/password \
             /ecommerce/dev/sns/topic-arn /ecommerce/dev/services/product-url \
             /ecommerce/dev/services/cart-url /ecommerce/dev/services/user-url \
             /ecommerce/dev/services/order-url; do
  aws ssm delete-parameter --name $PARAM 2>/dev/null && echo "Deleted SSM param: $PARAM"
done

# ── Module 3: Frontend ───────────────────────────────────────────────────────

DISTRIBUTION_ID=$(aws cloudfront list-distributions \
  --query "DistributionList.Items[?contains(Origins.Items[0].DomainName, 'ecommerce-frontend-${ACCOUNT_ID}')].Id" \
  --output text)

# Disable distribution first
aws cloudfront get-distribution-config --id $DISTRIBUTION_ID > /tmp/cf-cleanup.json
ETAG=$(python3 -c "import json; print(json.load(open('/tmp/cf-cleanup.json'))['ETag'])")
python3 -c "
import json
cfg = json.load(open('/tmp/cf-cleanup.json'))['DistributionConfig']
cfg['Enabled'] = False
print(json.dumps(cfg))
" > /tmp/cf-cleanup-disabled.json
aws cloudfront update-distribution --id $DISTRIBUTION_ID \
  --if-match $ETAG --distribution-config file:///tmp/cf-cleanup-disabled.json > /dev/null
echo "Disabling CloudFront distribution (wait ~5 minutes before deleting)..."
aws cloudfront wait distribution-deployed --id $DISTRIBUTION_ID
NEW_ETAG=$(aws cloudfront get-distribution --id $DISTRIBUTION_ID --query 'ETag' --output text)
aws cloudfront delete-distribution --id $DISTRIBUTION_ID --if-match $NEW_ETAG && echo "Deleted CloudFront distribution"

BUCKET_NAME=ecommerce-frontend-$ACCOUNT_ID
aws s3 rm s3://$BUCKET_NAME --recursive > /dev/null
aws s3api delete-bucket --bucket $BUCKET_NAME && echo "Deleted S3 bucket: $BUCKET_NAME"

# ── Module 2: Cognito ────────────────────────────────────────────────────────

USER_POOL_ID=$(aws cognito-idp list-user-pools --max-results 60 \
  --query 'UserPools[?Name==`ecommerce-app`].Id' --output text)
aws cognito-idp delete-user-pool --user-pool-id $USER_POOL_ID && echo "Deleted Cognito User Pool"

# ── Module 1: Networking ─────────────────────────────────────────────────────

VPC_ID=$(aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=ecommerce-vpc" \
  --query 'Vpcs[0].VpcId' --output text)

# Delete NAT Gateway and release EIP
NAT_GW_ID=$(aws ec2 describe-nat-gateways \
  --filter "Name=vpc-id,Values=$VPC_ID" "Name=state,Values=available" \
  --query 'NatGateways[0].NatGatewayId' --output text)
ALLOC_ID=$(aws ec2 describe-nat-gateways \
  --nat-gateway-ids $NAT_GW_ID \
  --query 'NatGateways[0].NatGatewayAddresses[0].AllocationId' --output text)
aws ec2 delete-nat-gateway --nat-gateway-id $NAT_GW_ID > /dev/null
echo "Deleting NAT Gateway..."
aws ec2 wait nat-gateway-deleted --nat-gateway-ids $NAT_GW_ID
aws ec2 release-address --allocation-id $ALLOC_ID && echo "Released Elastic IP"

# Delete VPC (also removes subnets, route tables, IGW, security groups)
aws ec2 delete-vpc --vpc-id $VPC_ID && echo "Deleted VPC: $VPC_ID"

echo ""
echo "Cleanup complete!"
echo ""
echo "NOTE: Route53 hosted zone and ACM certificate were created manually."
echo "Please delete them manually from the AWS Console to avoid ongoing charges:"
echo "  - ACM Console (us-east-1): Delete the SSL certificate"
echo "  - Route53 Console: Delete DNS records, then delete the hosted zone"
```

</details>
