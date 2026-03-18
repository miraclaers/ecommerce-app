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
                          → SQS Queue (Shipping)
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

This should automatically update the SQS Policy to allow SQS:SendMessage action for SNS Topic.

Go to SQS Queue -> Queue Policies and Verify.

If you don't see Policy statement for SNS Topic then you can also manually change the policy like below (replace region, account id, topic arn):
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

## 7.7 Test Notification Workflow

1. **Place an order** through the frontend
2. **Order service publishes** to SNS topic
3. **SNS sends email** Check email for order notification
4. **SNS also sends** message to SQS queue for shipping. Verify messages in the SQS queue -> Send and receive message -> Poll for messages.

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
