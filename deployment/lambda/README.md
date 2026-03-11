# Lambda Functions for AWS Deployment

This directory contains Lambda functions used in the AWS deployment.

## notification_handler.py

Lambda function that processes order notifications from SQS and sends confirmation emails via SES.

### Trigger
- **SQS Queue:** `ecommerce-notification-queue`
- **Batch size:** 10 messages
- **Event source:** SNS → SQS → Lambda

### Environment Variables
- `SENDER_EMAIL`: Verified email address in SES (e.g., `noreply@yourdomain.com`)

### IAM Permissions Required
- `sqs:ReceiveMessage`
- `sqs:DeleteMessage`
- `sqs:GetQueueAttributes`
- `ses:SendEmail`
- `logs:CreateLogGroup`
- `logs:CreateLogStream`
- `logs:PutLogEvents`

### Deployment
See **[Module 7: Event-Driven Architecture](./module7-event-driven.md)** for deployment instructions.

### Local Testing
This Lambda function is not used in local deployment. The local deployment uses the notification service container instead.
