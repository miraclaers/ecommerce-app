# Module 7: Event-Driven Architecture

## Overview
Set up event-driven architecture using Amazon SNS and SQS for asynchronous order processing and email notifications in the ecommerce application.

## What We'll Build
- **7.1** SNS topic for order events
- **7.2** SQS queue for order processing
- **7.3** Email subscription for notifications
- **7.4** Configure SNS-SQS integration
- **7.5** Update Parameter Store with SNS topic ARN
- **7.6** Test event-driven workflow

## Architecture
```
Order Service → SNS Topic → SQS Queue → Notification Service
                    ↓
               Email Subscription
```

When an order is placed:
1. **Order Service** publishes message to SNS topic
2. **SNS** delivers message to SQS queue and email subscriber
3. **Notification Service** processes SQS messages for additional logic
4. **Email notification** sent directly via SNS

---

## 7.1 Create SNS Topic

### SNS Topic Configuration

1. **SNS Console → Topics → Create topic**
2. **Type:** Standard
3. **Name:** `ecommerce-order-notifications`
4. **Display name:** `eCommerce Order Notifications`
5. **Create topic**

### Note Topic ARN

6. **Copy the Topic ARN** (e.g., `arn:aws:sns:<region>:<account-id>:ecommerce-order-notifications`)
7. **Save this ARN** - we'll use it in Parameter Store and order service

---

## 7.2 Create SQS Queue

### SQS Queue Configuration

1. **SQS Console → Queues → Create queue**
2. **Type:** Standard queue
3. **Name:** `ecommerce-order-processing`
4. **Configuration:** Keep defaults
   - Visibility timeout: 30 seconds
   - Message retention period: 4 days
   - Delivery delay: 0 seconds
5. **Create queue**

### Note Queue Details

6. **Copy the Queue URL** (e.g., `https://sqs.<region>.amazonaws.com/<account-id>/ecommerce-order-processing`)
7. **Copy the Queue ARN** (from queue details)

---

## 7.3 Create Email Subscription

### Email Subscription Configuration

1. **Go to SNS topic → Subscriptions → Create subscription**
2. **Topic ARN:** Select `ecommerce-order-notifications`
3. **Protocol:** Email
4. **Endpoint:** Enter your email address (e.g., `admin@yourcompany.com`)
5. **Create subscription**

### Confirm Email Subscription

6. **Check your email** for confirmation message from AWS
7. **Click "Confirm subscription"** in the email
8. **Verify status** shows "Confirmed" in SNS console

---

## 7.4 Configure SNS-SQS Integration

### Create SQS Subscription

1. **Go to SNS topic → Subscriptions → Create subscription**
2. **Topic ARN:** Select `ecommerce-order-notifications`
3. **Protocol:** Amazon SQS
4. **Endpoint:** Enter the SQS queue ARN from step 7.2
5. **Create subscription**

### Configure SQS Queue Policy

1. **Go to SQS queue → Access policy → Edit**
2. **Add policy to allow SNS to send messages:**

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
      "Resource": "arn:aws:sqs:<region>:<account-id>:ecommerce-order-processing",
      "Condition": {
        "StringEquals": {
          "aws:SourceArn": "arn:aws:sns:<region>:<account-id>:ecommerce-order-notifications"
        }
      }
    }
  ]
}
```

3. **Replace `<region>` and `<account-id>`** with your actual values
4. **Save policy**

---

## 7.5 Update Parameter Store

### SNS Topic ARN Parameter

1. **Systems Manager Console → Parameter Store → Create parameter**
2. **Name:** `/ecommerce/dev/sns/topic-arn`
3. **Type:** String
4. **Value:** `arn:aws:sns:<region>:<account-id>:ecommerce-order-notifications`

This parameter will be used by the order service to publish messages to SNS.

---

## 7.6 Test Event-Driven Workflow

### Test SNS Topic

**Publish Test Message:**
1. **Go to SNS topic → Publish message**
2. **Subject:** `Test Order Notification`
3. **Message body:**
```json
{
  "orderId": "test-001",
  "userId": "user-123",
  "totalAmount": 99.99,
  "status": "confirmed",
  "timestamp": "2024-01-01T12:00:00Z"
}
```
4. **Publish message**

### Verify Message Delivery

**Check Email:**
- You should receive an email notification with the test message

**Check SQS Queue:**
1. **Go to SQS queue → Send and receive messages**
2. **Poll for messages**
3. **Verify test message** appears in the queue

### Test with Order Service

Once the order service is deployed (from Module 4), it will automatically:
1. **Read SNS topic ARN** from Parameter Store
2. **Publish messages** when orders are created
3. **Trigger notifications** via SNS to both email and SQS

### Message Flow Verification

**Expected Flow:**
1. **Order placed** → Order service publishes to SNS
2. **SNS delivers** → Email notification sent
3. **SNS delivers** → Message queued in SQS
4. **Notification service** → Processes SQS messages (future enhancement)

### Troubleshooting

**Email not received:**
- Check email subscription is confirmed
- Verify email address is correct
- Check spam folder

**SQS not receiving messages:**
- Verify SQS queue policy allows SNS access
- Check SNS subscription is confirmed
- Ensure queue ARN is correct in subscription

**Order service not publishing:**
- Verify Parameter Store has correct SNS topic ARN
- Check ECS task role has SNS publish permissions
- Review CloudWatch logs for errors

## Architecture Benefits

1. **Decoupled Services:** Order service doesn't directly handle notifications
2. **Scalable Processing:** SQS allows asynchronous message processing
3. **Multiple Subscribers:** Easy to add more notification channels
4. **Reliable Delivery:** SNS ensures message delivery to all subscribers
5. **Event-Driven:** Reactive architecture based on business events
6. **Future Extensibility:** Easy to add more services and notification types

## Next Steps
Proceed to **[Module 8: DNS & SSL](./module8-dns-ssl.md)** to configure custom domain and SSL certificates.
