# Module 8: Notification and Integration (SNS and SQS)

## Overview
Set up simple notification flows using Amazon SNS and SQS for order notifications and integration with 3rd party vendors. 

> [!IMPORTANT]
Ideally for the email notification we should use Amazon SES (Simple Email Service) where we have the Lambda function subscription for SNS topic and Lambda triggers an email to the email id from the order event using SES. However by default SES service is in Sandbox mode in AWS account and it applies restriction on sending emails from un-verified sender. We have to ask AWS to move SES service out of SandBox and enable it for the Production use and this may take few days. 

Hence, we are going to send email directly to fixed email id using the Amazon SNS.

## In this module
- Create SNS topic for order events
- Create SQS queue for order shipping
- Configure SNS subscriptions (Email + SQS)
- Create Parameter in SSM Parameter Store for SNS Topic ARN and Restart order service
- Test the notification workflow

## Architecture

<img width="600" height="300" alt="image" src="https://github.com/user-attachments/assets/c55b177f-80be-445f-a274-27593192005d" />

## 7.1 Create SNS Topic

### SNS Topic Configuration

1. **SNS Console → Topics → Create topic**
2. **Type:** Standard
3. **Name:** `ecommerce-order-events`
4. **Display name:** `eCommerce Order Events`
5. **Create topic**

### Note Topic ARN

6. **Copy the Topic ARN** (e.g., `arn:aws:sns:<region>:<account-id>:ecommerce-order-events`)
7. **Save this ARN** - we'll use it in Parameter Store


## 7.2 Create SQS Queue for Logging

### SQS Queue Configuration

1. **SQS Console → Queues → Create queue**
2. **Type:** Standard queue
3. **Name:** `ecommerce-order-shipping`
4. **Create queue**


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

This should automatically update the SQS queue Policy to allow SQS:SendMessage action for SNS Topic.

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

## 7.4 Update Parameter Store

### SNS Topic ARN Parameter

1. **Systems Manager Console → Parameter Store → Create parameter**
2. **Name:** `/ecommerce/dev/sns/topic-arn`
3. **Type:** String
4. **Value:** `arn:aws:sns:<region>:<account-id>:ecommerce-order-events`
5. **Create parameter**

This parameter is already created and used by the order service to publish messages to SNS.

## 7.5 Restart the Order Service to featch SNS Topic ARN

1. **ECS Cluster -> Services -> Order Service -> Force new deployment**
2. Wait until Order Service status changes to 1 Task Running

This will make sure that Order Service featches SNS Topic ARN from SSM Parameter Store and publishes order event on to the topic.


## 7.6 Test Notification Workflow

1. **Place an order** through the frontend
2. **Order service publishes** to SNS topic
3. **SNS sends email** Check email for order notification
4. **SNS also sends** message to SQS queue for shipping. Verify messages in the SQS queue -> Send and receive message -> Poll for messages.

### Troubleshooting

**Email not received:**
- Check spam folder
- Verify email subscription is confirmed
- Check Order service logs in the CloudWatch logs under /ecs/order-service logs group.

**SQS not receiving messages:**
- Verify SQS queue policy allows SNS topic to send messages
- Check SQS subscription is confirmed
- Check Order service logs in the CloudWatch logs under /ecs/order-service logs group.

## Next Steps
Proceed to **[Module 9: Custom Domain & SSL](./module09-custom-domain-and-ssl.md)**
