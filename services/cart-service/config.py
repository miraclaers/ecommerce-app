import os
import boto3
from pydantic_settings import BaseSettings
from pydantic import ConfigDict

class Settings(BaseSettings):
    model_config = ConfigDict(frozen=False, env_file=".env")
    environment: str = "local"
    
    # Default values for local development
    aws_region: str = "us-east-1"
    dynamodb_endpoint: str = "http://localstack:4566"
    carts_table: str = "ecommerce-cart"
    
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
                    f'/ecommerce/{self.environment}/aws/region'
                ],
                WithDecryption=True
            )
            
            # Update values
            for param in response['Parameters']:
                name = param['Name']
                value = param['Value']
                
                if name.endswith('/aws/region'):
                    self.aws_region = value
                    
        except Exception as e:
            print(f"Warning: Could not load parameters from Parameter Store: {e}")
            print("Using default/environment variable values")

settings = Settings()
