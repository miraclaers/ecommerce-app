import json
import boto3
import os

ses_client = boto3.client('ses')

def lambda_handler(event, context):
    """
    Lambda function to process order notifications from SQS
    and send confirmation emails via SES
    """
    
    sender_email = os.environ.get('SENDER_EMAIL', 'noreply@yourdomain.com')
    
    for record in event['Records']:
        try:
            # Parse SNS message from SQS
            body = json.loads(record['body'])
            
            # SNS wraps the actual message
            if 'Message' in body:
                order_data = json.loads(body['Message'])
            else:
                order_data = body
            
            # Build email body
            email_body = f"""
Order Confirmation

Thank you for your order!

Order ID: {order_data['order_id']}
Total Amount: ${order_data['total_amount']:.2f}

Items:
"""
            
            for item in order_data['items']:
                email_body += f"\n- Product: {item['product_id']}, Quantity: {item['quantity']}, Price: ${item['price']:.2f}"
            
            email_body += "\n\nThank you for shopping with us!"
            
            # Send email via SES
            response = ses_client.send_email(
                Source=sender_email,
                Destination={
                    'ToAddresses': [order_data['user_email']]
                },
                Message={
                    'Subject': {
                        'Data': f"Order Confirmation - #{order_data['order_id']}"
                    },
                    'Body': {
                        'Text': {
                            'Data': email_body
                        }
                    }
                }
            )
            
            print(f"Email sent successfully to {order_data['user_email']} for order {order_data['order_id']}")
            print(f"SES MessageId: {response['MessageId']}")
            
        except Exception as e:
            print(f"Error processing message: {str(e)}")
            raise  # Re-raise to keep message in queue for retry
    
    return {
        'statusCode': 200,
        'body': json.dumps('Emails processed successfully')
    }
