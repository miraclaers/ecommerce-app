# Module 7: Event-Driven Architecture with Lambda

## Overview
Set up event-driven architecture using Amazon SNS, SQS, Lambda, and SES for asynchronous order processing and email notifications.

## What We'll Build
- **7.1** Configure Amazon SES for sending emails
- **7.2** Create SNS topic for order events
- **7.3** Create SQS queue for order processing
- **7.4** Create Lambda function for email notifications
- **7.5** Configure SNS-SQS-Lambda integration
- **7.6** Update Parameter Store with SNS topic ARN
- **7.7** Test event-driven workflow

## Architecture
```
Order Service → SNS Topic → SQS Queue → Lambda Function → SES (Email)
```

When an order is placed:
1. **Order Service** publishes message to SNS topic
2. **SNS** delivers message to SQS queue
3. **SQS** triggers Lambda function
4. **Lambda** sends order confirmation email via SES

---

## 7.1 Configure Amazon SES

### Verify Email Address (Sandbox Mode)

1. **SES Console → Verified identities → Create identity**
2. **Identity type:** Email address
3. **Email address:** Enter your email (e.g., `noreply@yourdomain.com`)
4. **Create identity**

### Confirm Email Verification

5. **Check your email** for verification message from AWS
6. **Click verification link** in the email
7. **Verify status** shows "Verified" in SES console

### Verify Recipient Email (For Testing)

8. **Repeat steps 1-7** for the email address that will receive order confirmations
   - This is needed because SES starts in sandbox mode
   - In sandbox mode, you can only send to verified addresses

### Note: Production Setup

For production, you'll need to:
- Request production access (move out of sandbox)
- Verify your domain instead of individual emails
- Configure DKIM and SPF records

**For this tutorial, sandbox mode is sufficient.**

---

## 7.2 Create SNS Topic

### SNS Topic Configuration

1. **SNS Console → Topics → Create topic**
2. **Type:** Standard
3. **Name:** `ecommerce-order-events`
4. **Display name:** `eCommerce Order Events`
5. **Create topic**

### Note Topic ARN

6. **Copy the Topic ARN** (e.g., `arn:aws:sns:<region>:<account-id>:ecommerce-order-events`)
7. **Save this ARN** - we'll use it in Parameter Store

---

## 7.3 Create SQS Queue

### SQS Queue Configuration

1. **SQS Console → Queues → Create queue**
2. **Type:** Standard queue
3. **Name:** `ecommerce-notification-queue`
4. **Configuration:**
   - Visibility timeout: 60 seconds (Lambda execution time)
   - Message retention period: 4 days
   - Delivery delay: 0 seconds
5. **Create queue**

### Note Queue Details

6. **Copy the Queue URL**
7. **Copy the Queue ARN** (from queue details)

### Configure SQS Queue Policy

8. **Access policy → Edit**
9. **Add policy to allow SNS to send messages:**

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
      "Resource": "arn:aws:sqs:<region>:<account-id>:ecommerce-notification-queue",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "arn:aws:sns:<region>:<account-id>:ecommerce-order-events"
        }
      }
    }
  ]
}
```

10. **Replace `<region>` and `<account-id>`** with your values
11. **Save policy**

---

## 7.4 Create Lambda Function

### Create IAM Role for Lambda

1. **IAM Console → Roles → Create role**
2. **Trusted entity:** AWS service → Lambda
3. **Permissions:** Attach policies:
   - `AWSLambdaSQSQueueExecutionRole` (for SQS trigger)
   - `AmazonSESFullAccess` (for sending emails)
4. **Role name:** `ecommerce-notification-lambda-role`
5. **Create role**

### Create Lambda Function

1. **Lambda Console → Functions → Create function**
2. **Function name:** `ecommerce-notification-handler`
3. **Runtime:** Python 3.11
4. **Architecture:** x86_64
5. **Execution role:** Use existing role → `ecommerce-notification-lambda-role`
6. **Create function**

### Upload Lambda Code

7. **Download the Lambda code:**
   - Get `notification_handler.py` from `deployment/lambda/` directory

8. **In Lambda console → Code tab:**
   - Delete the default `lambda_function.py`
   - Create new file: `lambda_function.py`
   - Copy content from `notification_handler.py`
   - **Deploy** the code

### Configure Environment Variables

9. **Configuration → Environment variables → Edit**
10. **Add variable:**
    - Key: `SENDER_EMAIL`
    - Value: Your verified SES email (e.g., `noreply@yourdomain.com`)
11. **Save**

### Configure Lambda Settings

12. **Configuration → General configuration → Edit**
13. **Timeout:** 30 seconds
14. **Memory:** 128 MB
15. **Save**

---

## 7.5 Configure SNS-SQS-Lambda Integration

### Subscribe SQS to SNS Topic

1. **Go to SNS topic → Subscriptions → Create subscription**
2. **Topic ARN:** Select `ecommerce-order-events`
3. **Protocol:** Amazon SQS
4. **Endpoint:** Enter the SQS queue ARN
5. **Create subscription**
6. **Verify status** shows "Confirmed"

### Add SQS Trigger to Lambda

1. **Go to Lambda function → Add trigger**
2. **Select trigger:** SQS
3. **SQS queue:** Select `ecommerce-notification-queue`
4. **Batch size:** 10
5. **Batch window:** 0 seconds
6. **Enable trigger:** Yes
7. **Add**

### Verify Integration

The flow is now complete:
```
SNS → SQS → Lambda → SES
```

---

## 7.6 Update Parameter Store

### SNS Topic ARN Parameter

1. **Systems Manager Console → Parameter Store → Create parameter**
2. **Name:** `/ecommerce/dev/sns/topic-arn`
3. **Type:** String
4. **Value:** `arn:aws:sns:<region>:<account-id>:ecommerce-order-events`
5. **Create parameter**

This parameter will be used by the order service to publish messages to SNS.

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
```

3. **Publish message**
4. **Check email** - order confirmation should arrive

### Monitor Lambda Execution

1. **Lambda Console → Monitor → Logs**
2. **View logs in CloudWatch**
3. **Verify:**
   - Lambda was triggered
   - Email sent successfully
   - No errors

### Test with Order Service

Once the order service is deployed and updated:
1. **Place an order** through the frontend
2. **Order service publishes** to SNS
3. **SNS delivers** to SQS
4. **Lambda processes** message
5. **SES sends** confirmation email

### Troubleshooting

**Email not received:**
- Verify sender email is verified in SES
- Verify recipient email is verified (sandbox mode)
- Check Lambda CloudWatch logs for errors
- Check spam folder

**Lambda not triggered:**
- Verify SQS trigger is enabled
- Check SQS queue has messages
- Review Lambda execution role permissions

**SQS not receiving messages:**
- Verify SQS queue policy allows SNS
- Check SNS subscription is confirmed
- Ensure queue ARN is correct

**SES errors:**
- Verify email addresses in SES console
- Check you're in correct AWS region
- Review SES sending limits (sandbox: 200 emails/day)

## Architecture Benefits

1. **Serverless:** No infrastructure to manage for notifications
2. **Cost-effective:** Pay only when emails are sent
3. **Auto-scaling:** Lambda scales automatically with message volume
4. **Decoupled:** Order service doesn't wait for email sending
5. **Reliable:** SQS ensures message delivery and retry logic
6. **Event-driven:** Reactive architecture based on business events

## Cost Estimate

For 1000 orders/month:
- SNS: ~$0.50 (1000 publishes)
- SQS: ~$0.40 (1000 requests)
- Lambda: Free tier (1M requests/month)
- SES: ~$0.10 (1000 emails)

**Total: ~$1/month**

## Next Steps
Proceed to **[Module 8: DNS & SSL](./module8-dns-ssl.md)** to configure custom domain and SSL certificates.
