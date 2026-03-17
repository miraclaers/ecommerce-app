# Module 0: Prerequisites

## Overview
Ensure you have the required tools and access before starting the AWS deployment.

## Prerequisites

### 1. AWS Account
- An AWS account with administrative access
- AWS credentials configured (Access Key ID and Secret Access Key)

### 2. Local Workstation (Linux / Mac)
- A Linux or macOS machine to run the deployment steps
- Windows users can use WSL2 (Ubuntu)

### 3. Required Tools
- **Git** — version control
- **Docker** — container runtime for building and pushing images
- **Node.js 20+** and **npm** — for building the React frontend
- **AWS CLI v2** — for interacting with AWS services

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
bash install-prerequisites.sh
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

If all commands work without errors, you're ready to proceed to **[Module 1: Networking Foundation](./module01-networking.md)**.
