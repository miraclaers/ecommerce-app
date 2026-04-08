# Module 10: Cleanup

## Overview
Clean up all AWS resources created during this project to avoid ongoing charges.

## Cleanup Order

Delete resources in reverse order of creation to avoid dependency issues:

### 1. DNS & SSL (Module 9)
- Route53 DNS records (A records, CNAME records)
- ACM SSL certificate
- Route53 Public hosted zone

> These were created manually. Please delete them from the AWS Console:
> - **Route53 Console:** Delete DNS records → Delete hosted zone
> - **ACM Console (us-east-1):** Delete the SSL certificate

### 2. Notification (Module 8)
- SNS subscriptions (email, SQS)
- SQS queue
- SNS topic

<details>
<summary><strong>CLI equivalent</strong></summary>

```bash
SNS_TOPIC_ARN=$(aws sns list-topics \
  --query "Topics[?ends_with(TopicArn, ':ecommerce-order-events')].TopicArn" --output text)

for SUB_ARN in $(aws sns list-subscriptions-by-topic --topic-arn $SNS_TOPIC_ARN \
  --query 'Subscriptions[?SubscriptionArn!=`PendingConfirmation`].SubscriptionArn' --output text); do
  aws sns unsubscribe --subscription-arn $SUB_ARN && echo "Unsubscribed: $SUB_ARN"
done

aws sns delete-topic --topic-arn $SNS_TOPIC_ARN && echo "Deleted SNS topic"

SQS_QUEUE_URL=$(aws sqs get-queue-url --queue-name ecommerce-order-shipping \
  --query 'QueueUrl' --output text)
aws sqs delete-queue --queue-url $SQS_QUEUE_URL && echo "Deleted SQS queue"
```

</details>

### 3. API Gateway (Module 6)
- API Gateway HTTP API
- VPC Link

<details>
<summary><strong>CLI equivalent</strong></summary>

```bash
API_ID=$(aws apigatewayv2 get-apis \
  --query 'Items[?Name==`ecommerce-api`].ApiId' --output text)
aws apigatewayv2 delete-api --api-id $API_ID && echo "Deleted API Gateway"

VPC_LINK_ID=$(aws apigatewayv2 get-vpc-links \
  --query 'Items[?Name==`ecommerce-vpc-link`].VpcLinkId' --output text)
aws apigatewayv2 delete-vpc-link --vpc-link-id $VPC_LINK_ID && echo "Deleted VPC Link"
```

</details>

### 4. ECS Services & Cluster (Module 5)

<details>
<summary><strong>CLI equivalent</strong></summary>

```bash
for SVC in product-service cart-service user-service order-service; do
  aws ecs update-service --cluster ecommerce-cluster \
    --service ecommerce-$SVC --desired-count 0 > /dev/null
done

echo "Waiting for all tasks to drain..."
for SVC in product-service cart-service user-service order-service; do
  aws ecs wait services-stable --cluster ecommerce-cluster --services ecommerce-$SVC
  aws ecs delete-service --cluster ecommerce-cluster \
    --service ecommerce-$SVC --force > /dev/null && echo "Deleted ECS service: $SVC"
done

aws ecs delete-cluster --cluster ecommerce-cluster > /dev/null && echo "Deleted ECS cluster"

for SVC in product-service cart-service user-service order-service; do
  for REV in $(aws ecs list-task-definitions \
    --family-prefix ecommerce-$SVC --query 'taskDefinitionArns' --output text); do
    aws ecs deregister-task-definition --task-definition $REV > /dev/null
  done
  echo "Deregistered task definitions: $SVC"
done
```

</details>

### 5. ECR Repositories (Module 5)

<details>
<summary><strong>CLI equivalent</strong></summary>

```bash
for SVC in product-service cart-service user-service order-service; do
  aws ecr delete-repository \
    --repository-name ecommerce/$SVC --force > /dev/null && echo "Deleted ECR repo: $SVC"
done
```

</details>

### 6. ALB & Target Groups (Module 5)

<details>
<summary><strong>CLI equivalent</strong></summary>

```bash
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
```

</details>

### 7. IAM Roles (Module 5)

<details>
<summary><strong>CLI equivalent</strong></summary>

```bash
for POLICY_ARN in $(aws iam list-attached-role-policies \
  --role-name ecommerce-ecs-task-role \
  --query 'AttachedPolicies[*].PolicyArn' --output text); do
  aws iam detach-role-policy \
    --role-name ecommerce-ecs-task-role --policy-arn $POLICY_ARN && echo "Detached: $POLICY_ARN"
done
aws iam delete-role --role-name ecommerce-ecs-task-role && echo "Deleted ECS task role"
```

</details>

### 8. RDS Database (Module 4)

<details>
<summary><strong>CLI equivalent</strong></summary>

```bash
aws rds delete-db-instance \
  --db-instance-identifier ecommercedb-instance \
  --skip-final-snapshot > /dev/null
echo "Deleting RDS instance (this takes a few minutes)..."
aws rds wait db-instance-deleted --db-instance-identifier ecommercedb-instance
echo "RDS instance deleted"

aws rds delete-db-subnet-group \
  --db-subnet-group-name ecommerce-db-subnet-group && echo "Deleted DB subnet group"
```

</details>

### 9. DynamoDB & Parameter Store (Module 4)

<details>
<summary><strong>CLI equivalent</strong></summary>

```bash
aws dynamodb delete-table --table-name ecommerce-products > /dev/null && echo "Deleted DynamoDB: ecommerce-products"
aws dynamodb delete-table --table-name ecommerce-cart > /dev/null && echo "Deleted DynamoDB: ecommerce-cart"

for PARAM in /ecommerce/dev/aws/region /ecommerce/dev/db/host /ecommerce/dev/db/password \
             /ecommerce/dev/sns/topic-arn /ecommerce/dev/services/product-url \
             /ecommerce/dev/services/cart-url /ecommerce/dev/services/user-url \
             /ecommerce/dev/services/order-url; do
  aws ssm delete-parameter --name $PARAM 2>/dev/null && echo "Deleted SSM param: $PARAM"
done
```

</details>

### 10. CloudFront & S3 (Module 3)

<details>
<summary><strong>CLI equivalent</strong></summary>

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
DISTRIBUTION_ID=$(aws cloudfront list-distributions \
  --query "DistributionList.Items[?contains(Origins.Items[0].DomainName, 'ecommerce-frontend-${ACCOUNT_ID}')].Id" \
  --output text)

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
echo "Disabling CloudFront distribution (wait ~5 minutes)..."
aws cloudfront wait distribution-deployed --id $DISTRIBUTION_ID
NEW_ETAG=$(aws cloudfront get-distribution --id $DISTRIBUTION_ID --query 'ETag' --output text)
aws cloudfront delete-distribution --id $DISTRIBUTION_ID --if-match $NEW_ETAG && echo "Deleted CloudFront distribution"

BUCKET_NAME=ecommerce-frontend-$ACCOUNT_ID
aws s3 rm s3://$BUCKET_NAME --recursive > /dev/null
aws s3api delete-bucket --bucket $BUCKET_NAME && echo "Deleted S3 bucket: $BUCKET_NAME"
```

</details>

### 11. Cognito (Module 2)

<details>
<summary><strong>CLI equivalent</strong></summary>

```bash
USER_POOL_ID=$(aws cognito-idp list-user-pools --max-results 60 \
  --query 'UserPools[?Name==`ecommerce-app`].Id' --output text)
aws cognito-idp delete-user-pool --user-pool-id $USER_POOL_ID && echo "Deleted Cognito User Pool"
```

</details>

### 12. Networking - NAT Gateway & VPC (Module 1)

<details>
<summary><strong>CLI equivalent</strong></summary>

```bash
VPC_ID=$(aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=ecommerce-vpc" \
  --query 'Vpcs[0].VpcId' --output text)

NAT_GW_ID=$(aws ec2 describe-nat-gateways \
  --filter "Name=vpc-id,Values=$VPC_ID" "Name=state,Values=available" \
  --query 'NatGateways[0].NatGatewayId' --output text)
ALLOC_ID=$(aws ec2 describe-nat-gateways --nat-gateway-ids $NAT_GW_ID \
  --query 'NatGateways[0].NatGatewayAddresses[0].AllocationId' --output text)
aws ec2 delete-nat-gateway --nat-gateway-id $NAT_GW_ID > /dev/null
echo "Deleting NAT Gateway..."
aws ec2 wait nat-gateway-deleted --nat-gateway-ids $NAT_GW_ID
aws ec2 release-address --allocation-id $ALLOC_ID && echo "Released Elastic IP"

# Detach and delete Internet Gateway
IGW_ID=$(aws ec2 describe-internet-gateways \
  --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
  --query 'InternetGateways[0].InternetGatewayId' --output text)
aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID && echo "Deleted Internet Gateway"

# Delete subnets
for SUBNET_ID in $(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'Subnets[*].SubnetId' --output text); do
  aws ec2 delete-subnet --subnet-id $SUBNET_ID && echo "Deleted subnet: $SUBNET_ID"
done

# Delete non-main route tables
for RT_ID in $(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'RouteTables[?Associations[0].Main!=`true`].RouteTableId' --output text); do
  aws ec2 delete-route-table --route-table-id $RT_ID && echo "Deleted route table: $RT_ID"
done

# Delete non-default security groups
for SG_ID in $(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text); do
  aws ec2 delete-security-group --group-id $SG_ID && echo "Deleted security group: $SG_ID"
done

aws ec2 delete-vpc --vpc-id $VPC_ID && echo "Deleted VPC"
```

</details>
