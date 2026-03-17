# Module 8: Event-Driven Architecture with SNS

## Overview
Set up simple event-driven architecture using Amazon SNS for asynchronous order notifications and shipping vendor.

## What We'll Build
- **7.1** Create SNS topic for order events
- **7.2** Create SQS queue for order shipping
- **7.3** Configure SNS subscriptions (Email + SQS)
- **7.4** Update SSM Parameter Store with SNS topic ARN
- **7.5** Test the notification workflow

## Architecture
```
Order Service → SNS Topic → Email Subscription (Direct)
                        → SQS Queue (Logging)
```

When an order is placed:
1. **Order Service** publishes message to SNS topic
2. **SNS** sends email notification directly to subscriber
3. **SNS** also sends message to SQS queue for shipping

---

## 7.1 Create SNS Topic

### SNS Topic Configuration

1. **SNS Console → Topics → Create topic**
2. **Type:** Standard
3. **Name:** `ecommerce-order-events`
### Topic Configuration

1. **SNS Console → Topics → Create topic**
2. **Type:** Standard
3. **Name:** `ecommerce-order-events`
4. **Display name:** `eCommerce Order Events`
5. **Create topic**

### Note Topic ARN

6. **Copy the Topic ARN** (e.g., `arn:aws:sns:<region>:<account-id>:ecommerce-order-events`)
7. **Save this ARN** - we'll use it in Parameter Store

---

## 7.2 Create SQS Queue for Logging

### SQS Queue Configuration

1. **SQS Console → Queues → Create queue**
2. **Type:** Standard queue
3. **Name:** `ecommerce-order-shipping`
4. **Create queue**

### Configure SQS Queue Policy

6. **Access policy → Edit**
7. **Add policy to allow SNS to send messages:**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "sns.amazonaws.com"
      },
      "Action": "sqs:SendMessage",
      "Resource": "arn:aws:sqs:<region>:<account-id>:ecommerce-order-shipping",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "arn:aws:sns:<region>:<account-id>:ecommerce-order-events"
        }
      }
    }
  ]
}
```

8. **Replace `<region>` and `<account-id>`** with your values
9. **Save policy**

---

## 7.3 Configure SNS Subscriptions

### Email Subscription

1. **Go to SNS topic → Subscriptions → Create subscription**
2. **Topic ARN:** Select `ecommerce-order-events`
3. **Protocol:** Email
4. **Endpoint:** Enter your email address (e.g., `admin@yourdomain.com`)
5. **Create subscription**
6. **Check your email** for confirmation message
7. **Click "Confirm subscription"** link in the email
8. **Verify status** shows "Confirmed" in SNS console

### SQS Subscription for Shipping

1. **Create subscription**
2. **Topic ARN:** Select `ecommerce-order-events`
3. **Protocol:** Amazon SQS
4. **Endpoint:** Enter the SQS queue ARN from step 7.2
5. **Create subscription**
6. **Verify status** shows "Confirmed"

### Subscription Summary

You now have two subscriptions:
- **Email:** Direct notifications to your email
- **SQS:** Message for shipping vendor

---

## 7.4 Update Parameter Store

### SNS Topic ARN Parameter

1. **Systems Manager Console → Parameter Store → Create parameter**
2. **Name:** `/ecommerce/dev/sns/topic-arn`
3. **Type:** String
4. **Value:** `arn:aws:sns:<region>:<account-id>:ecommerce-order-events`
5. **Create parameter**

This parameter is already created and used by the order service to publish messages to SNS.

---

## 7.7 Test Event-Driven Workflow

### Test Lambda Function Directly

1. **Lambda Console → Test tab**
2. **Create test event:**
   - Event name: `test-order`
   - Template: SQS
3. **Replace event JSON:**

```json
{
  "Records": [
    {
      "body": "{\"Message\": \"{\\\"order_id\\\": \\\"test-001\\\", \\\"user_email\\\": \\\"your-verified-email@example.com\\\", \\\"total_amount\\\": 99.99, \\\"items\\\": [{\\\"product_id\\\": \\\"prod-001\\\", \\\"quantity\\\": 2, \\\"price\\\": 49.99}]}\"}"
    }
  ]
}
```

4. **Replace `your-verified-email@example.com`** with your verified SES email
5. **Test**
6. **Check your email** - you should receive order confirmation

### Test SNS to Lambda Flow

1. **Go to SNS topic → Publish message**
2. **Message body:**

```json
{
  "order_id": "test-002",
  "user_email": "your-verified-email@example.com",
  "total_amount": 149.99,
  "items": [
    {
      "product_id": "prod-001",
      "quantity": 1,
      "price": 89.99
    },
    {
      "product_id": "prod-002",
      "quantity": 2,
      "price": 29.99
    }
  ]
}
## 7.5 Test Event-Driven Workflow

### Test SNS Topic Directly

1. **SNS Console → Topics → ecommerce-order-events**
2. **Publish message → Create message:**
   ```json
   {
     "order_id": "test-123",
     "user_email": "customer@example.com",
     "total_amount": 99.99,
     "items": [
       {
         "product_id": "prod-001",
         "name": "Test Product",
         "quantity": 1,
         "price": 99.99
       }
     ]
   }
   ```
3. **Publish message**
4. **Check your email** - notification should arrive directly from SNS
5. **Check SQS queue** - message should appear in `ecommerce-order-shipping`

### Test with Order Service

Once the order service is deployed:
1. **Place an order** through the frontend
2. **Order service publishes** to SNS topic
3. **SNS sends email** directly to subscriber
4. **SNS also sends** message to SQS queue for shipping

### Verify Message Flow

**Check Email:**
- Order notification email from SNS
- Subject: "Notification from Amazon SNS Topic"
- Body contains the order JSON

**Check SQS Queue:**
1. **SQS Console → ecommerce-order-shipping**
2. **Send and receive messages → Poll for messages**
3. **Verify message** contains order details

### Troubleshooting

**Email not received:**
- Check spam folder
- Verify email subscription is confirmed
- Ensure SNS topic has correct permissions

**SQS not receiving messages:**
- Verify SQS queue policy allows SNS
- Check SNS subscription is confirmed
- Ensure queue ARN is correct in policy

**Order service errors:**
- Verify Parameter Store has correct SNS topic ARN
- Check ECS task role has SNS permissions
- Review CloudWatch logs for order service

## Next Steps
Proceed to **[Module 9: Custom Domain & SSL](./module09-custom-domain-and-ssl.md)** to configure custom domain and SSL certificates.
