#!/bin/bash

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &>/dev/null; then
    echo "AWS CLI is not configured. Please configure AWS CLI and try again."
    exit 1
fi

# Instance parameters
INSTANCE_TYPE_X86="t3.2xlarge"      # Instance type for x86_64 architecture
INSTANCE_TYPE_ARM="t4g.2xlarge"      # Instance type for arm64 architecture
SECURITY_GROUP_ID="sg-08308b3f0eb73d194"   # Replace with your Security Group ID
IAM_INSTANCE_PROFILE="AdminIPRole"   # Replace with your IAM Instance Profile Name
KEY_PAIR_NAME="virginia"  # Replace with your desired Key Pair Name

# Array of OS and architectures on which test is to be performed
OS_LIST=("Amazon_Linux_2023" "Amazon_Linux_2" "RHEL_8" "RHEL_9" "SuSE_12" "SuSE_15" "Ubuntu_20" "Ubuntu_22" "Ubuntu_24")
ARCHITECTURES=("x86_64" "arm64")

# Function to find the latest AMI ID for a given OS and architecture
get_latest_ami() {
    local os="$1"
    local architecture="$2"
    local ami_id=""

    case "$os" in
        "Amazon_Linux_2023")
            ami_id=$(aws ec2 describe-images --owners amazon --filters \
                "Name=name,Values=al2023-ami-2023*" \
                "Name=architecture,Values=$architecture" \
                "Name=state,Values=available" \
                --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
                --output text)
            ;;
        "Amazon_Linux_2")
            ami_id=$(aws ec2 describe-images --owners amazon --filters \
                "Name=name,Values=amzn2-ami-kernel-5*" \
                "Name=architecture,Values=$architecture" \
                "Name=state,Values=available" \
                --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
                --output text)
            ;;
        "RHEL_8")
            ami_id=$(aws ec2 describe-images --owners amazon --filters \
                "Name=name,Values=RHEL-8*" \
                "Name=architecture,Values=$architecture" \
                "Name=state,Values=available" \
                --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
                --output text)
            ;;
        "RHEL_9")
            ami_id=$(aws ec2 describe-images --owners amazon --filters \
                "Name=name,Values=RHEL-9.4.0*" \
                "Name=architecture,Values=$architecture" \
                "Name=state,Values=available" \
                --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
                --output text)
            ;;
        "SuSE_12")
            ami_id=$(aws ec2 describe-images --owners amazon --filters \
                "Name=description,Values='SUSE Linux Enterprise Server 15 SP6 (HVM, 64-bit, SSD-Backed)'" \
                "Name=architecture,Values=$architecture" \
                "Name=state,Values=available" \
                --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
                --output text)
            ;;
        "SuSE_15")
            ami_id=$(aws ec2 describe-images --owners amazon --filters \
                "Name=description,Values='SUSE Linux Enterprise Server 15 SP6 (HVM, 64-bit, SSD-Backed)'" \
                "Name=architecture,Values=$architecture" \
                "Name=state,Values=available" \
                --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
                --output text)
            ;;
        "Ubuntu_20")
            ami_id=$(aws ec2 describe-images --owners amazon --filters \
                "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-focal-20.04-*" \
                "Name=architecture,Values=$architecture" \
                "Name=state,Values=available" \
                --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
                --output text)
            ;;
        "Ubuntu_22")
            ami_id=$(aws ec2 describe-images --owners amazon --filters \
                "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-*" \
                "Name=architecture,Values=$architecture" \
                "Name=state,Values=available" \
                --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
                --output text)
            ;;
        "Ubuntu_24")
            ami_id=$(aws ec2 describe-images --owners amazon --filters \
                "Name=name,Values=ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-*" \
                "Name=architecture,Values=$architecture" \
                "Name=state,Values=available" \
                --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
                --output text)
            ;;
        *)
            echo "Unsupported OS: $os"
            return 1
            ;;
    esac

    # Check if the AMI ID is valid
    if [ -z "$ami_id" ] || [[ "$ami_id" == "None" ]]; then
        echo "Error: No valid AMI found for $os ($architecture)."
        return 1
    fi

    echo "$ami_id"
}

# # setting AWS path
# set_aws_path(){
#     if command -v aws &>/dev/null; then
#         echo "AWS CLI found in the system path."
#     else
#         if [ -f "/usr/local/bin/aws" ]; then
#             ln -sf /usr/local/aws-cli/v2/current/bin/aws /bin/aws
#             echo "Soft link created for AWS CLI and path set."
#         fi
#     fi
# }


# Function to generate user data script
generate_user_data() {
    cat <<'EOF'
#!/bin/bash -x
sleep 60;

# Function to set AWS path
set_aws_path(){
    if command -v aws &>/dev/null; then
        echo "AWS CLI found in the system path."
    else
        if [ -f "/usr/local/bin/aws" ]; then
            ln -sf /usr/local/aws-cli/v2/current/bin/aws /bin/aws
            echo "Soft link created for AWS CLI and path set."
        fi
    fi
}

# Function to install a package if its not already installed
install_package() {
    local package="$1"
    echo "Checking if $package is installed..."
    if ! command -v "$package" &>/dev/null; then
        echo "$package not found. Installing..."
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            case "$ID" in
                amzn|rhel|centos)
                    yum install -y "$package" || dnf install -y "$package"
                    ;;
                ubuntu|debian)
                    apt-get install -y "$package" || snap install "$package"
                    ;;
                sles)
                    zypper install -y "$package"
                    wait
                    ;;
                *)
                    echo "Unsupported linux distribution : $ID. Please install $package manually."
                    exit 1;
                    ;;
            esac
        else
            echo "OS information not available. Please install $package manually."
            exit 1
        fi
    else
        echo "$package is already installed."
    fi
}

# Install wget and unzip
install_package "wget"
install_package "unzip"

# Check AWS CLI version
if ! aws --version 2>/dev/null | grep -q "aws-cli/2"; then
    echo "AWS CLI version 2 is not installed. Installing AWS CLI v2..."
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            amzn|rhel|centos|sles|ubuntu|debian)
                curl "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip" -o "awscliv2.zip" && unzip awscliv2.zip && ./aws/install
                set_aws_path
                ;;
            *)
                echo "Unsupported OS for AWS CLI installation."
                ;;
        esac
    fi
fi

sleep 10;

# Placeholder for three custom shell commands
echo "downloading script..."
wget https://raw.githubusercontent.com/sattyagrah/AWSHealthCLI/refs/heads/main/aws_health.sh
echo "changing permission..."
chmod u+x aws_health.sh
echo "executing..."
./aws_health.sh
EOF
}

# Function to launch an instance with the latest AMI
launch_instance() {
    local ami_id="$1"
    local os="$2"
    local architecture="$3"
    local instance_name="${os// /_}_$architecture"  # Create instance name by replacing spaces with underscores

    # Determine the instance type based on architecture
    if [[ "$architecture" == "x86_64" ]]; then
        instance_type="$INSTANCE_TYPE_X86"
    else
        instance_type="$INSTANCE_TYPE_ARM"
    fi

    echo "Launching $os ($architecture) instance with AMI ID: $ami_id"

    aws ec2 run-instances --image-id "$ami_id" --instance-type "$instance_type" \
        --security-group-ids "$SECURITY_GROUP_ID" \
        --iam-instance-profile Name="$IAM_INSTANCE_PROFILE" \
        --key-name "$KEY_PAIR_NAME" \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance_name}]" \
        --user-data "$(generate_user_data)" \
        --output text &>/dev/null
}

# Main script to iterate through each OS and architecture
for os in "${OS_LIST[@]}"; do
    for architecture in "${ARCHITECTURES[@]}"; do
        ami_id=$(get_latest_ami "$os" "$architecture")
        if [ -n "$ami_id" ] && [[ "$ami_id" != "Unsupported OS: $os" ]]; then
            launch_instance "$ami_id" "$os" "$architecture"
        else
            echo "No valid AMI found for $os ($architecture). Skipping instance launch."
        fi
    done
done