# Module 0: Prerequisites

## Overview
Set up the required tools and environment before starting the AWS deployment. This module ensures you have everything needed to follow the deployment guide.

## What You'll Need
1. **AWS Account** - With administrative access
2. **AWS CLI** - Command line interface for AWS
3. **Docker** - For building and running containers
4. **Git** - For cloning the repository
5. **Text Editor** - For editing configuration files (VS Code recommended)

## Step 1: AWS Account Setup

### AWS Console
1. **Create AWS Account** (if you don't have one)
   - Go to [aws.amazon.com](https://aws.amazon.com)
   - Click "Create an AWS Account"
   - Follow the registration process
   - **Note:** You'll need a credit card for verification

2. **Create IAM User** (Recommended for security)
   - Go to IAM Console → Users → Create user
   - Username: `deployment-user`
   - Access type: Programmatic access
   - Permissions: Attach existing policy → `AdministratorAccess`
   - Create user and **save the Access Key ID and Secret Access Key**

### Security Best Practices
- Enable MFA (Multi-Factor Authentication) on your root account
- Use IAM users instead of root account for daily operations
- Never share your AWS credentials

## Step 2: Install AWS CLI

### Windows
```bash
# Download and install AWS CLI v2
# Go to: https://awscli.amazonaws.com/AWSCLIV2.msi
# Run the installer

# Verify installation
aws --version
```

### macOS
```bash
# Using Homebrew (recommended)
brew install awscli

# Or download installer
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /

# Verify installation
aws --version
```

### Linux (Ubuntu/Debian)
```bash
# Download and install
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Verify installation
aws --version
```

### Configure AWS CLI
```bash
# Configure with your credentials
aws configure

# Enter when prompted:
# AWS Access Key ID: [Your Access Key]
# AWS Secret Access Key: [Your Secret Key]
# Default region name: ap-south-1
# Default output format: json

# Test configuration
aws sts get-caller-identity
```

**Expected output:**
```json
{
    "UserId": "AIDACKCEVSQ6C2EXAMPLE",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/deployment-user"
}
```

## Step 3: Install Docker

### Windows
1. **Download Docker Desktop**
   - Go to [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop)
   - Download Docker Desktop for Windows
   - Run the installer and follow instructions
   - Restart your computer if prompted

2. **Enable WSL 2** (if using Windows 10/11)
   - Docker Desktop will prompt you to install WSL 2
   - Follow the instructions to enable it

### macOS
```bash
# Using Homebrew (recommended)
brew install --cask docker

# Or download Docker Desktop
# Go to: https://www.docker.com/products/docker-desktop
# Download and install Docker Desktop for Mac
```

### Linux (Ubuntu/Debian)
```bash
# Update package index
sudo apt-get update

# Install Docker
sudo apt-get install docker.io

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add your user to docker group (to run without sudo)
sudo usermod -aG docker $USER

# Log out and log back in, then test
docker --version
```

### Verify Docker Installation
```bash
# Check Docker version
docker --version

# Test Docker with hello-world
docker run hello-world

# Expected output should include:
# "Hello from Docker!"
```

## Step 4: Install Git

### Windows
1. **Download Git**
   - Go to [git-scm.com](https://git-scm.com/download/win)
   - Download and run the installer
   - Use default settings during installation

### macOS
```bash
# Git is usually pre-installed, check version
git --version

# If not installed, use Homebrew
brew install git
```

### Linux (Ubuntu/Debian)
```bash
# Install Git
sudo apt-get update
sudo apt-get install git

# Verify installation
git --version
```

### Configure Git (Optional)
```bash
# Set your name and email (for commits)
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

## Step 5: Clone the Repository

```bash
# Clone the ecommerce application repository
git clone https://github.com/awswithchetan/ecommerce-web-app.git

# Navigate to the project directory
cd ecommerce-web-app

# Verify the structure
ls -la

# Expected directories:
# - services/          (microservices code)
# - frontend/          (React application)
# - deployment/        (deployment guides)
# - local-deployment/  (local testing setup)
```

## Step 6: Verify Prerequisites

Run this verification script to ensure everything is set up correctly:

```bash
#!/bin/bash
echo "=== Prerequisites Verification ==="

# Check AWS CLI
echo "1. Checking AWS CLI..."
if command -v aws &> /dev/null; then
    echo "✅ AWS CLI installed: $(aws --version)"
    
    # Test AWS credentials
    if aws sts get-caller-identity &> /dev/null; then
        echo "✅ AWS credentials configured"
        echo "   Account: $(aws sts get-caller-identity --query Account --output text)"
        echo "   Region: $(aws configure get region)"
    else
        echo "❌ AWS credentials not configured or invalid"
        echo "   Run: aws configure"
    fi
else
    echo "❌ AWS CLI not installed"
fi

# Check Docker
echo -e "\n2. Checking Docker..."
if command -v docker &> /dev/null; then
    echo "✅ Docker installed: $(docker --version)"
    
    # Test Docker daemon
    if docker info &> /dev/null; then
        echo "✅ Docker daemon running"
    else
        echo "❌ Docker daemon not running"
        echo "   Start Docker Desktop or run: sudo systemctl start docker"
    fi
else
    echo "❌ Docker not installed"
fi

# Check Git
echo -e "\n3. Checking Git..."
if command -v git &> /dev/null; then
    echo "✅ Git installed: $(git --version)"
else
    echo "❌ Git not installed"
fi

# Check repository
echo -e "\n4. Checking repository..."
if [ -d "services" ] && [ -d "deployment" ]; then
    echo "✅ Repository cloned correctly"
    echo "   Services found: $(ls services/ | wc -l)"
else
    echo "❌ Repository not cloned or incorrect directory"
    echo "   Run: git clone https://github.com/awswithchetan/ecommerce-web-app.git"
fi

echo -e "\n=== Verification Complete ==="
```

Save this as `check-prerequisites.sh` and run:
```bash
chmod +x check-prerequisites.sh
./check-prerequisites.sh
```

## Troubleshooting

### Common Issues

**1. AWS CLI "command not found"**
- Ensure AWS CLI is installed correctly
- Restart your terminal/command prompt
- Check if it's in your PATH

**2. Docker permission denied (Linux)**
```bash
# Add user to docker group
sudo usermod -aG docker $USER
# Log out and log back in
```

**3. AWS credentials invalid**
```bash
# Reconfigure AWS CLI
aws configure

# Or check existing configuration
aws configure list
```

**4. Docker Desktop not starting (Windows/Mac)**
- Ensure virtualization is enabled in BIOS
- Check system requirements
- Restart Docker Desktop

### Getting Help
- **AWS CLI:** [AWS CLI Documentation](https://docs.aws.amazon.com/cli/)
- **Docker:** [Docker Documentation](https://docs.docker.com/)
- **Git:** [Git Documentation](https://git-scm.com/doc)

## Cost Awareness

### Free Tier Resources
AWS provides a free tier for new accounts (12 months):
- EC2: 750 hours/month of t2.micro instances
- RDS: 750 hours/month of db.t2.micro
- S3: 5GB storage
- Lambda: 1M requests/month

### Estimated Costs for This Tutorial
- **Development (4-hour session):** $10-15
- **Full deployment (24 hours):** $50-75
- **Monthly production:** $200-250

**Important:** Always clean up resources after learning to avoid unexpected charges.

## Next Steps

Once all prerequisites are verified:
1. ✅ AWS CLI configured with valid credentials
2. ✅ Docker installed and running
3. ✅ Git installed
4. ✅ Repository cloned
5. ✅ All verification checks pass

**You're ready to proceed to [Module 1: Networking Foundation](./module1-networking.md)**

## Security Reminders

- Never commit AWS credentials to Git repositories
- Use IAM users instead of root account
- Enable MFA on your AWS account
- Regularly rotate access keys
- Monitor AWS billing dashboard for unexpected charges
