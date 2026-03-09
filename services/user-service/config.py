from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    environment: str = "local"
    aws_region: str = "ap-south-1"
    db_host: str = "postgres"
    db_port: int = 5432
    db_name: str = "ecommercedb"
    db_user: str = "postgres"
    db_password: str = "postgres"
    
    class Config:
        env_file = ".env"

settings = Settings()
