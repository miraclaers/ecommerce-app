# Module 0: Prerequisites

## Overview
Ensure you have the required tools and access before starting the AWS deployment.

## Prerequisites

### 1. AWS Account & CLI
- **AWS Account** with administrative access
- **AWS CLI v2** installed and configured ([Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html))
- **Configured credentials** with appropriate permissions

### 2. Development Tools
- **Docker** installed and running ([Installation Guide](https://docs.docker.com/get-docker/))
- **Git** installed ([Installation Guide](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git))
- **Node.js 20+** and npm for frontend builds

## Step 1: Clone Repository

First, clone the repository to your local machine:

```bash
git clone https://github.com/awswithchetan/ecommerce-web-app.git
cd ecommerce-web-app
```

## Step 2: Install Required Tools

**Option 1: Automated Installation (Recommended)**

Run the installation script that automatically detects your OS:

```bash
./install-prerequisites.sh
```

This script supports:
- macOS (uses Homebrew)
- Ubuntu/Debian (uses apt)
- Amazon Linux/RHEL/CentOS (uses yum)

**Option 2: Manual Installation**

Follow the individual installation guides linked above for each tool.

## Step 3: Verify Tool Installation

```bash
# Verify all tools are installed
aws --version
docker --version
node --version
npm --version
git --version
```

## Step 4: Verify AWS CLI Access

```bash
# Test AWS CLI configuration
aws sts get-caller-identity

# Expected output should show your account details
{
    "UserId": "AIDACKCEVSQ6C2EXAMPLE",
    "Account": "123456789012", 
    "Arn": "arn:aws:iam::123456789012:user/your-user"
}

# Test region access (should list available regions)
aws ec2 describe-regions --query 'Regions[0:3].RegionName'
```

## Step 5: Configure AWS CLI (if needed)
aws ec2 describe-regions --query 'Regions[0:3].RegionName' --output table
```

## Step 2: Verify Docker

```bash
# Check Docker installation
docker --version

# Test Docker functionality
docker run hello-world
```

## Step 3: Clone Repository

```bash
# Clone the ecommerce application repository
git clone https://github.com/awswithchetan/ecommerce-web-app.git

# Navigate to project directory
cd ecommerce-web-app

# Verify repository structure
ls -la

# Expected directories:
# - services/          (microservices code)
# - frontend/          (React application) 
# - deployment/        (deployment guides)
# - local-deployment/  (local testing setup)
```

If all commands work without errors, you're ready to proceed to **[Module 1: Networking Foundation](./module1-networking.md)**.
