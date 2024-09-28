#!/bin/bash

# Function to set the PATH if AWS CLI is installed but not found and create a soft link if necessary
set_aws_path() {
    if command -v aws &>/dev/null; then
        echo "AWS CLI found in the system path."
    else
        # Try to set the path manually if installed
        if [ -f "/usr/local/bin/aws" ]; then
            export PATH=$PATH:/usr/local/bin
            echo "AWS CLI path set to /usr/local/bin."
        elif [ -f "/usr/bin/aws" ]; then
            export PATH=$PATH:/usr/bin
            echo "AWS CLI path set to /usr/bin."
        elif [ -f "/usr/local/aws-cli/v2/current/bin/aws" ]; then
            # Create a soft link if AWS CLI is installed but not linked correctly
            ln -s /usr/local/aws-cli/v2/current/bin/aws /usr/local/bin/aws
            export PATH=$PATH:/usr/local/bin
            echo "Soft link created for AWS CLI and path set."
        else
            echo "AWS CLI path could not be set automatically. Please ensure it's installed correctly."
            exit 1
        fi
    fi
}

# Function to check if a package is installed; if not, install it
install_package() {
    local package="$1"
    echo "Checking if $package is installed..."
    if ! command -v "$package" &>/dev/null; then
        echo "$package is not installed. Attempting to install..."
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            case "$ID" in
                amzn|rhel|centos|sles)
                    yum install -y "$package" || dnf install -y "$package"
                    ;;
                ubuntu|debian)
                    apt-get update
                    apt-get install -y "$package" || snap install "$package"
                    ;;
                suse)
                    zypper install -y "$package"
                    ;;
                *)
                    echo "Unsupported Linux distribution: $ID. Please install $package manually."
                    exit 1
                    ;;
            esac
        else
            echo "OS information not available. Please install $package manually."
            exit 1
        fi

        # Confirm package installation
        if command -v "$package" &>/dev/null; then
            echo "$package installed successfully."
        else
            echo "Failed to install $package. Exiting..."
            exit 1
        fi
    else
        echo "$package is already installed."
    fi
}

# Install wget and unzip if not present
install_package "wget"
install_package "unzip"

# Function to install AWS CLI version 2 if not installed
install_aws_cli() {
    echo "Checking if AWS CLI version 2 is installed..."
    if ! aws --version 2>/dev/null | grep -q "aws-cli/2"; then
        echo "AWS CLI version 2 is not installed. Installing AWS CLI v2..."
        curl "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip" -o "awscliv2.zip"
        unzip awscliv2.zip
        ./aws/install

        # Confirm AWS CLI installation
        set_aws_path
        if aws --version 2>/dev/null | grep -q "aws-cli/2"; then
            echo "AWS CLI version 2 installed successfully."
        else
            echo "Failed to install AWS CLI version 2. Exiting..."
            exit 1
        fi
    else
        echo "AWS CLI version 2 is already installed."
    fi
}

# Install AWS CLI version 2
install_aws_cli

# Check if AWS CLI is configured
echo "Checking if AWS CLI is configured..."
if ! aws sts get-caller-identity &>/dev/null; then
    echo "AWS CLI is not configured. Please configure AWS CLI and try again."
    exit 1
else
    echo "AWS CLI is configured correctly."
fi

echo "Script execution completed successfully."
