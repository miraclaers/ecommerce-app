import boto3
import json
import time
from config import settings

def get_sqs_client():
    if settings.environment == "local":
        return boto3.client(
            'sqs',
            endpoint_url=settings.sqs_endpoint,
            region_name=settings.aws_region,
            aws_access_key_id='test',
            aws_secret_access_key='test'
        )
    else:
        return boto3.client('sqs', region_name=settings.aws_region)

def get_ses_client():
    if settings.environment == "local":
        return boto3.client(
            'ses',
            endpoint_url=settings.ses_endpoint,
            region_name=settings.aws_region,
            aws_access_key_id='test',
            aws_secret_access_key='test'
        )
    else:
        return boto3.client('ses', region_name=settings.aws_region)

def send_order_confirmation_email(order_data):
    """Send order confirmation email via SES"""
    ses = get_ses_client()
    
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
    
    try:
        if settings.environment == "local":
            # LocalStack SES just logs emails - save to file instead
            import os
            from datetime import datetime
            
            os.makedirs('/tmp/emails', exist_ok=True)
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            filename = f"/tmp/emails/order_{order_data['order_id']}_{timestamp}.txt"
            
            with open(filename, 'w') as f:
                f.write(f"To: {order_data['user_email']}\n")
                f.write(f"Subject: Order Confirmation - #{order_data['order_id']}\n")
                f.write(f"\n{email_body}")
            
            print(f"[LOCAL] Email saved to: {filename}")
            print(f"[LOCAL] Sending email to: {order_data['user_email']}")
        else:
            ses.send_email(
                Source=settings.sender_email,
                Destination={'ToAddresses': [order_data['user_email']]},
                Message={
                    'Subject': {'Data': f"Order Confirmation - #{order_data['order_id']}"},
                    'Body': {'Text': {'Data': email_body}}
                }
            )
        print(f"Email sent successfully to {order_data['user_email']}", flush=True)
    except Exception as e:
        print(f"Failed to send email: {str(e)}", flush=True)

def process_message(message):
    """Process a single SQS message"""
    try:
        # Parse SNS message
        body = json.loads(message['Body'])
        
        # SNS wraps the actual message
        if 'Message' in body:
            order_data = json.loads(body['Message'])
        else:
            order_data = body
        
        print(f"Processing order: {order_data['order_id']}", flush=True)
        send_order_confirmation_email(order_data)
        
        return True
    except Exception as e:
        print(f"Error processing message: {str(e)}", flush=True)
        return False

def main():
    """Main loop to poll SQS queue"""
    sqs = get_sqs_client()
    
    print(f"Notification Service started. Polling queue: {settings.sqs_queue_url}", flush=True)
    
    while True:
        try:
            response = sqs.receive_message(
                QueueUrl=settings.sqs_queue_url,
                MaxNumberOfMessages=10,
                WaitTimeSeconds=20  # Long polling
            )
            
            messages = response.get('Messages', [])
            
            if messages:
                print(f"Received {len(messages)} message(s)", flush=True)
                
                for message in messages:
                    if process_message(message):
                        # Delete message after successful processing
                        sqs.delete_message(
                            QueueUrl=settings.sqs_queue_url,
                            ReceiptHandle=message['ReceiptHandle']
                        )
                        print("Message processed and deleted", flush=True)
                    else:
                        print("Message processing failed, will retry", flush=True)
        
        except Exception as e:
            print(f"Error in main loop: {str(e)}", flush=True)
            time.sleep(5)

if __name__ == "__main__":
    main()
