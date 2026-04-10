# Module 0: Prerequisites

## Overview
Ensure you have the required tools and access before starting the AWS deployment.

## Prerequisites

### 1. AWS Account
- An AWS account with administrative access
- AWS CLI configured with Access Key ID and Secret Access Key

### 2. Local Workstation (Linux / Mac / Windows)
- A Linux or macOS machine to run the deployment steps
- Windows users can use WSL2 (Ubuntu)

<details>
<summary><strong>How to create VM using Windows WSL</strong></summary>

<br>

1. Open **Command Prompt** or **PowerShell**

2. Run the following command to create a new Ubuntu VM:

```bash
wsl --install -d Ubuntu --name <name-of-your-vm>
```

3. To connect to your VM (anytime later):

```bash
wsl -d <name-of-your-vm>
```
</details>

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

## Step 2: Install Required Tools (if you don't have it already)

**Automated Installation**

Run the installation script that automatically detects your OS:

```bash
bash install-prerequisites.sh
```

## Step 3: Verify Tool Installation

```bash
# Verify all tools are installed
aws --version
docker --version
node --version
npm --version
git --version
```

## Step 4: Configure and Verify AWS CLI Access

### Configure AWS CLI (if not configured already)

You'll need an AWS Access Key ID and Secret Access Key. To create one:
1. **AWS Console → IAM → Users → Your user → Security credentials → Create access key**
2. Choose **CLI** as the use case and create the key
3. Copy the **Access Key ID** and **Secret Access Key**

Then run:

```bash
aws configure
```

You'll be prompted for:
```
AWS Access Key ID [None]: <your-access-key-id>
AWS Secret Access Key [None]: <your-secret-access-key>
Default region name [None]: ap-south-1        # enter your preferred region
Default output format [None]: json
```

### Verify AWS CLI Access

```bash
# Test AWS CLI is configured correctly
aws sts get-caller-identity

# Expected output should show your account details
{
    "UserId": "AIDACKCEVSQ6C2EXAMPLE",
    "Account": "123456789012", 
    "Arn": "arn:aws:iam::123456789012:user/your-user"
}
```

## Step 5: Set Default Region

```bash
# Set a default region so you don't need --region in every command
export AWS_DEFAULT_REGION=ap-south-1   # change to your region
```

## Next Steps
Proceed to **[Module 1: Networking Foundation](./module01-networking.md)**
