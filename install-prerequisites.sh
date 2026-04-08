#!/bin/bash
set -e

echo "=========================================="
echo "Installing Prerequisites for eCommerce App"
echo "=========================================="

# Detect OS
OS="$(uname -s)"
case "${OS}" in
    Linux*)     MACHINE=Linux;;
    Darwin*)    MACHINE=Mac;;
    *)          MACHINE="UNKNOWN:${OS}"
esac

echo "Detected OS: $MACHINE"
echo ""

if [ "$MACHINE" = "UNKNOWN:${OS}" ]; then
    echo "Unsupported operating system: ${OS}"
    echo "This script supports Linux and macOS only."
    exit 1
fi

# ==========================================
# macOS Installation
# ==========================================
if [ "$MACHINE" = "Mac" ]; then
    echo "Installing prerequisites for macOS..."
    echo ""
    
    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        echo "Homebrew already installed"
    fi
    
    # Install Docker Desktop
    if ! command -v docker &> /dev/null; then
        echo "Installing Docker Desktop..."
        echo "Please download and install Docker Desktop from:"
        echo "https://www.docker.com/products/docker-desktop"
        echo ""
        echo "After installation, start Docker Desktop and return here."
        read -p "Press Enter once Docker Desktop is installed and running..."
    else
        echo "Docker already installed"
    fi
    
    # Install Node.js
    if ! command -v node &> /dev/null; then
        echo "Installing Node.js 20 LTS..."
        brew install node@20
        brew link node@20
    else
        echo "Node.js already installed"
    fi
    
    # Install Git
    if ! command -v git &> /dev/null; then
        echo "Installing Git..."
        brew install git
    else
        echo "Git already installed"
    fi
    
    # Install AWS CLI
    if ! command -v aws &> /dev/null; then
        echo "Installing AWS CLI..."
        brew install awscli
    else
        echo "AWS CLI already installed"
    fi
    
    # Install jq
    if ! command -v jq &> /dev/null; then
        echo "Installing jq..."
        brew install jq
    else
        echo "jq already installed"
    fi

# ==========================================
# Linux Installation
# ==========================================
elif [ "$MACHINE" = "Linux" ]; then
    echo "Installing prerequisites for Linux..."
    echo ""
    
    # Detect Linux distribution
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    else
        echo "Cannot detect Linux distribution"
        exit 1
    fi
    
    echo "Detected distribution: $DISTRO"
    echo ""
    
    # Ubuntu/Debian
    if [ "$DISTRO" = "ubuntu" ] || [ "$DISTRO" = "debian" ]; then
        echo "Using apt package manager..."
        
        # Update packages
        sudo apt-get update -y
        
        # Install Docker
        if ! command -v docker &> /dev/null; then
            echo "Installing Docker..."
            sudo apt-get install -y docker.io
            sudo systemctl start docker
            sudo systemctl enable docker
            sudo usermod -aG docker $USER
        else
            echo "Docker already installed"
        fi
        
        # Install Docker Compose
        if ! command -v docker-compose &> /dev/null; then
            echo "Installing Docker Compose..."
            sudo apt-get install -y docker-compose
        else
            echo "Docker Compose already installed"
        fi
        
        # Install Node.js
        if ! command -v node &> /dev/null; then
            echo "Installing Node.js 20 LTS..."
            curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
            sudo apt-get install -y nodejs
        else
            echo "Node.js already installed"
        fi
        
        # Install Git
        if ! command -v git &> /dev/null; then
            echo "Installing Git..."
            sudo apt-get install -y git
        else
            echo "Git already installed"
        fi
        
        # Install jq
        if ! command -v jq &> /dev/null; then
            echo "Installing jq..."
            sudo apt-get install -y jq
        else
            echo "jq already installed"
        fi
        
        # Install AWS CLI
        if ! command -v aws &> /dev/null; then
            echo "Installing AWS CLI..."
            curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
            sudo apt-get install -y unzip
            unzip awscliv2.zip
            sudo ./aws/install
            rm -rf aws awscliv2.zip
        else
            echo "AWS CLI already installed"
        fi
    
    # Amazon Linux / RHEL / CentOS
    elif [ "$DISTRO" = "amzn" ] || [ "$DISTRO" = "rhel" ] || [ "$DISTRO" = "centos" ]; then
        echo "Using yum package manager..."
        
        # Update packages
        sudo yum update -y
        
        # Install Docker
        if ! command -v docker &> /dev/null; then
            echo "Installing Docker..."
            sudo yum install -y docker
            sudo systemctl start docker
            sudo systemctl enable docker
            sudo usermod -aG docker $USER
        else
            echo "Docker already installed"
        fi
        
        # Install Docker Compose
        if ! command -v docker-compose &> /dev/null; then
            echo "Installing Docker Compose..."
            COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
            sudo curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            sudo chmod +x /usr/local/bin/docker-compose
            sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
        else
            echo "Docker Compose already installed"
        fi
        
        # Install Node.js
        if ! command -v node &> /dev/null; then
            echo "Installing Node.js 20 LTS..."
            curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
            sudo yum install -y nodejs
        else
            echo "Node.js already installed"
        fi
        
        # Install Git
        if ! command -v git &> /dev/null; then
            echo "Installing Git..."
            sudo yum install -y git
        else
            echo "Git already installed"
        fi
        
        # Install jq
        if ! command -v jq &> /dev/null; then
            echo "Installing jq..."
            sudo yum install -y jq
        else
            echo "jq already installed"
        fi
        
        # Install AWS CLI
        if ! command -v aws &> /dev/null; then
            echo "Installing AWS CLI..."
            sudo yum install -y aws-cli
        else
            echo "AWS CLI already installed"
        fi
    
    else
        echo "Unsupported Linux distribution: $DISTRO"
        echo "Please install Docker, Docker Compose, Node.js 20, Git, and AWS CLI manually."
        exit 1
    fi
fi

echo ""
echo "=========================================="
echo "Installation Complete!"
echo "=========================================="
echo ""
echo "Installed versions:"
docker --version
docker-compose --version || docker compose version
node --version
npm --version
git --version
aws --version
jq --version

echo ""
if [ "$MACHINE" = "Linux" ]; then
    echo "IMPORTANT: You need to log out and log back in for Docker group permissions to take effect."
    echo "Or run: newgrp docker"
fi

echo ""
echo "Next steps:"
echo "1. Follow the AWS Deployment Guide: deployment/README.md"
echo ""
node --version
npm --version
git --version
echo ""
echo "IMPORTANT: You need to log out and log back in for Docker group changes to take effect."
echo "After re-login, verify Docker works without sudo: docker ps"
echo ""
