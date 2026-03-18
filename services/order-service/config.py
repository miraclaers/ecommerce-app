import os
import boto3
from pydantic_settings import BaseSettings
from pydantic import ConfigDict

class Settings(BaseSettings):
    model_config = ConfigDict(frozen=False, env_file=".env")

    environment: str = "local"
    
    # Default values for local development
    aws_region: str = "us-east-1"
    db_host: str = "postgres"
    db_port: int = 5432
    db_name: str = "ecommercedb"
    db_user: str = "postgres"
    db_password: str = "postgres"
    
    # Service URLs
    cart_service_url: str = "http://cart-service:8002"
    user_service_url: str = "http://user-service:8003"
    product_service_url: str = "http://product-service:8001"
    
    # AWS SNS
    sns_endpoint: str = "http://localstack:4566"
    sns_topic_arn: str = "arn:aws:sns:us-east-1:000000000000:order-events"
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        if self.environment != "local":
            self._load_from_parameter_store()
    
    def _load_from_parameter_store(self):
        try:
            # Use AWS_REGION environment variable (set in task definition)
            region = os.getenv('AWS_REGION', 'ap-south-1')
            ssm = boto3.client('ssm', region_name=region)
            
            # Get parameters
            response = ssm.get_parameters(
                Names=[
                    f'/ecommerce/{self.environment}/aws/region',
                    f'/ecommerce/{self.environment}/db/host',
                    f'/ecommerce/{self.environment}/db/password',
                    f'/ecommerce/{self.environment}/user-service-url',
                    f'/ecommerce/{self.environment}/cart-service-url',
                    f'/ecommerce/{self.environment}/product-service-url',
                    f'/ecommerce/{self.environment}/sns/topic-arn'
                ],
                WithDecryption=True
            )
            
            # Update values
            for param in response['Parameters']:
                name = param['Name']
                value = param['Value']
                
                if name.endswith('/aws/region'):
                    self.aws_region = value
                elif name.endswith('/db/host'):
                    self.db_host = value
                elif name.endswith('/db/password'):
                    self.db_password = value
                elif name.endswith('/user-service-url'):
                    self.user_service_url = value
                elif name.endswith('/cart-service-url'):
                    self.cart_service_url = value
                elif name.endswith('/product-service-url'):
                    self.product_service_url = value
                elif name.endswith('/sns/topic-arn'):
                    self.sns_topic_arn = value
                    
        except Exception as e:
            print(f"Warning: Could not load parameters from Parameter Store: {e}")
            print("Using default/environment variable values")

settings = Settings()
