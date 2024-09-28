#!/bin/bash

# Date of script execution (epoch)
script_date=$(date +%s)

# Function to check if AWS CLI is installed or not
check_cli_installed(){
    if ! command -v aws &> /dev/null; then
        echo "AWS CLI is not installed. Please install CLI (https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#getting-started-install-instructions) and try again. "
        exit 1
    fi 

    # using ternary operator
    # command -v aws &> /dev/null && echo "AWS CLI is installed." || echo "AWS CLI is not installed. Please install it and try again."
}

# Function to display spinner while commands run in background
show_spinner() {
    local pid=$1
    local delay=0.1    
    local spinstr='|/-\'
    
    echo "Fetching services..."

    # keep spinning
    while kill -0 $pid 2>/dev/null; do
        local temp=${spinstr#?}
        printf "[%c] " "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    echo "Done!"
}

# Function to get the AWS CLI version
get_aws_version(){
    local version
    version=$($(which aws) --version | awk -F '/' '{print $2}' | awk '{print $1}')
    echo "AWS CLI version : $version"

    # Check if AWS CLI is configured or not
    if ! aws sts get-caller-identity &>/dev/null; then
        echo "AWS CLI is not configured. Please configure AWS CLI (https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html) and try again."
        exit 1
    fi
}

# Function to list all services
list_all_services(){
    aws health describe-event-types --region us-east-1 --query 'sort_by(eventTypes, &service)[].service' --output yaml | uniq >> $(pwd)/aws_health_service.log 2>&1 &
    local pid=$!
    show_spinner $pid
}

# Function to list all event type codes
list_all_event_type_codes(){
    aws health describe-event-types --region us-east-1 --query 'sort_by(eventTypes, &code)[].code' --output yaml >> $(pwd)/aws_health_event_code.log 2>&1 &
    local pid=$!
    show_spinner $pid
}

# Function to list all event type codes of a particular service
list_all_event_type_codes_for_service(){
    select_service
    event_type_code_for_service=$(aws health describe-event-types --region us-east-1 --filter services=$service --query 'sort_by(eventTypes, &code)[].code' --output yaml)
    echo -e "\nThe list of event type codes for $service service is as follows : \n$event_type_code_for_service\n"
}

# Function to list event codes for a particular event type categories of a particular service
list_all_event_type_code_for_categories_in_service(){
    select_service
    select_category
    event_type_code_for_category_in_service=$(aws health describe-event-types --region us-east-1 --filter services=$service,eventTypeCategories=$category --query 'sort_by(eventTypes, &code)[].code' --output yaml)
    echo -e "\nThe list of event type codes for category [$category] in $service service is as follows : \n$event_type_code_for_category_in_service\n"
}

# Function to select service 
select_service(){
    # Allowed values
    allowed_service=("A2I" "ABUSE" "ACCOUNT" "ACM" "ACMPRIVATECA" "ACTIVATECONSOLE" "AIRFLOW" "AMPLIFY" "AMPLIFYADMIN" "AMPLIFYUIBUILDER" "AMS" "APIGATEWAY" "APPCONFIG" "APPFABRIC" "APPFLOW" "APPLICATIONINSIGHTS" "APPLICATION_AUTOSCALING" "APPMESH" "APPRUNNER" "APPSTREAM2" "APPSYNC" "APS" "ARTIFACT" "ATHENA" "AUDITMANAGER" "AUTOSCALING" "AWIS" "B2BI" "BACKUP" "BATCH" "BEDROCK" "BILLING" "BRAKET" "CASSANDRA" "CHATBOT" "CHIME" "CLEANROOMS" "CLIENT_VPN" "CLOUD9" "CLOUDDIRECTORY" "CLOUDFORMATION" "CLOUDFRONT" "CLOUDHSM" "CLOUDSEARCH" "CLOUDSHELL" "CLOUDTRAIL" "CLOUDWAN" "CLOUDWATCH" "CLOUDWATCHSYNTHETICS" "CODEARTIFACT" "CODEBUILD" "CODECATALYST" "CODECOMMIT" "CODEDEPLOY" "CODEGURU_PROFILER" "CODEGURU_REVIEWER" "CODEPIPELINE" "CODEWHISPERER" "COGNITO" "COMPREHEND" "COMPREHENDMEDICAL" "COMPUTE_OPTIMIZER" "CONFIG" "CONNECT" "CONSOLEMOBILEAPP" "CONTROLCATALOG" "CONTROLTOWER" "CORRETTO" "COSTPLANNER" "DATABREW" "DATAEXCHANGE" "DATAPIPELINE" "DATASYNC" "DATAZONE" "DAX" "DEADLINE" "DEEPCOMPOSER" "DEEPLENS" "DEEPRACER" "DETECTIVE" "DEVICEFARM" "DEVOPS-GURU" "DIODE" "DIRECTCONNECT" "DISCOVERY" "DLM" "DMS" "DOCDB" "DRS" "DS" "DYNAMODB" "EBS" "EBSONOUTPOSTS" "EC2" "EC2_INSTANCE_CONNECT" "EC2_SERIAL_CONSOLE" "ECR" "ECR_PUBLIC" "ECS" "EKS" "ELASTICACHE" "ELASTICBEANSTALK" "ELASTICFILESYSTEM" "ELASTICLOADBALANCING" "ELASTICMAPREDUCE" "ELASTICTRANSCODER" "ELEMENTAL" "EMR_SERVERLESS" "ENDUSERMESSAGING" "ENTITYRESOLUTION" "ES" "EVENTS" "EVENTS_SCHEDULER" "EVIDENTLY" "FARGATE" "FINSPACE" "FIREHOSE" "FIS" "FMS" "FORECAST" "FRAUDDETECTOR" "FREERTOS" "FSX" "GAMECAST" "GAMELIFT" "GEO" "GLACIER" "GLOBALACCELERATOR" "GLUE" "GRAFANA" "GREENGRASS" "GROUNDSTATION" "GUARDDUTY" "HEALTH" "HEALTHIMAGING" "HEALTHLAKE" "HONEYCODE" "IAM" "IAMIDENTITYCENTER" "IAMROLESANYWHERE" "IMAGEBUILDER" "IMPORTEXPORT" "INCIDENT_DETECTION_RESPONSE" "INFRASTRUCTUREPERFORMANCE" "INSPECTOR" "INSPECTOR2" "INTERNETCONNECTIVITY" "INTERNETMONITOR" "INTERREGIONVPCPEERING" "IOT" "IOT1CLICK" "IOTROBORUNNER" "IOTSMARTHOME" "IOTTWINMAKER" "IOT_ANALYTICS" "IOT_CORE" "IOT_DEVICE_ADVISOR" "IOT_DEVICE_DEFENDER" "IOT_DEVICE_MANAGEMENT" "IOT_EVENTS" "IOT_FLEETWISE" "IOT_SITEWISE" "IOT_WIRELESS" "IPAM" "IQ" "IVS" "KAFKA" "KENDRA" "KENDRA_RANKING" "KINESIS" "KINESISANALYTICS" "KINESIS_VIDEO" "KMS" "LAKEFORMATION" "LAMBDA" "LAUNCHWIZARD" "LEX" "LICENSE_MANAGER" "LIGHTSAIL" "LOCATION" "LOOKOUTMETRICS" "LOOKOUTVISION" "LOOKOUT_EQUIPMENT" "MACHINELEARNING" "MACIE" "MAINFRAME_MODERNIZATION" "MANAGEDBLOCKCHAIN" "MANAGEDSERVICES" "MANAGEMENTCONSOLE" "MARKETPLACE" "MEDIACONNECT" "MEDIACONVERT" "MEDIALIVE" "MEDIAPACKAGE" "MEDIASTORE" "MEDIATAILOR" "MEMORYDB" "MGH" "MGH_JOURNEYS" "MGN" "MIGRATIONHUBORCHESTRATOR" "MIGRATIONHUBSTRATEGY" "MOBILEANALYTICS" "MOBILETARGETING" "MONITRON" "MQ" "MULTIPLE_SERVICES" "NATGATEWAY" "NEPTUNE" "NETWORKFIREWALL" "NETWORK_ACCESS_ANALYZER" "NIMBLE" "NOTIFICATIONS" "OMICS" "ONE" "OPSWORKS" "OPSWORKS-CM" "OPSWORKS_CHEF" "OPSWORKS_PUPPET" "ORGANIZATIONS" "OUTPOSTS" "PANORAMA" "PARTNER-CENTRAL" "PAYMENTCRYPTOGRAPHY" "PCA_CONNECTOR_AD" "PCS" "PERSONALIZE" "PINPOINT" "POLLY" "PRICING" "PRIVATE_5G" "PROTON" "Q" "QAPPS" "QBUSINESS" "QLDB" "QUICKSIGHT" "RAM" "RBIN" "RDS" "REACHABILITY_ANALYZER" "REDSHIFT" "REFACTOR_SPACES" "REKOGNITION" "REPOSTSPACE" "RESILIENCEHUB" "RESOURCEEXPLORER" "RESOURCE_GROUPS" "RISK" "ROBOMAKER" "ROUTE53" "ROUTE53APPRECOVERYCONTROLLER" "ROUTE53DOMAINREGISTRATION" "ROUTE53PRIVATEDNS" "ROUTE53RESOLVER" "RUM" "S3" "S3_OUTPOSTS" "S3_REPLICATION_TIME_CONTROL" "SAGEMAKER" "SDB" "SDK" "SECRETSMANAGER" "SECURITY" "SECURITYHUB" "SECURITYLAKE" "SERVERLESSREPO" "SERVICECATALOG" "SERVICEDISCOVERY" "SERVICEQUOTAS" "SES" "SHIELD" "SIGNIN" "SIMSPACEWEAVER" "SMS" "SNOWBALL" "SNS" "SQS" "SSM" "SSM-SAP" "SSM_INCIDENTS" "SSO" "STATES" "STORAGEGATEWAY" "SUMERIAN" "SUPPORTCENTER" "SWAY" "SWF" "TAG" "TEXTRACT" "TIMESTREAM" "TNB" "TRAFFICMIRRORING" "TRANSCRIBE" "TRANSFER" "TRANSIT_GATEWAY" "TRANSLATE" "TRUSTEDADVISOR" "TS" "VERIFIED_ACCESS" "VERIFIED_PERMISSIONS" "VMIMPORTEXPORT" "VPC" "VPCE_PRIVATELINK" "VPC_LATTICE" "VPN" "WAF" "WELLARCHITECTED" "WICKR" "WORKDOCS" "WORKMAIL" "WORKSPACES" "WORKSPACESWEB" "XRAY")

    # Prompt the user for input
    read -p "Do you want to see the full list of supported service [y/n] (default: n) : " choice
    choice=${choice:-n}

    # If user wants to see the list 
    if [ "$choice" == "y" ]; then 
        list_all_services
        echo "Service list is available at $(pwd)/aws_health_service.log"
    fi

    # Prompt the user for input 
    read -p "Enter service (e.g., RDS) [default: EBS] : " service
    service=${service:-EBS}

    # Check if entered service is valid
    if [[ ! " ${allowed_service[*]} " =~ (^|[[:space:]])${service}($|[[:space:]]) ]]; then
        echo "Error: Illegal choice - $service. Run the script again and choose option 1 to see list of services."
        exit 1
    fi
}

# Function to select category
select_category(){
    # Allowed values
    valid_category=("issue" "scheduledChange" "accountNotification")

    # Prompt the user for input
    read -p "Enter category (issue/scheduledChange/accountNotification) [default: issue]: " category 
    category=${category:-issue}

    # Check if entered cateogry is valid
    if [[ ! " ${valid_category[*]} " =~ (^|[[:space:]])${category}($|[[:space:]]) ]]; then
        echo "Error: Illegal choice - $category. Correct choices are : issue | scheduledChange | accountNotification"
        exit 1
    fi
}

# Function to show menu
show_menu(){
    cat <<EOF
==== Menu ====    
1. List all services. 
2. List all event codes.
3. List all event codes of a particular service. 
4. List event codes for a particular event type categories of a particular service.
EOF
}

# Execution starts from here 
check_cli_installed

# Clean up old logs
if [ -f $(pwd)/aws_health_*.log ]; then
    rm -f $(pwd)/aws_health_*.log
fi

# Print execution time    
echo -e "Script executing at $script_date ($(date -ur $script_date || date -ud @$script_date))\n"

# Get AWS version    
get_aws_version

# Show the menu
show_menu

# Get user choice    
read -p "Select option of your choice [1/2/3/4] (default: 4) : " option
option=${option:-4}
    
# Execution based on user's choice
case $option in
    "1")
        list_all_services
        echo -e "Service list is present here : $(pwd)/aws_health_service.log\n"
        exit 0
        ;;

    "2")
        list_all_event_type_codes
        echo -e "Event codes is present here : $(pwd)/aws_health_event_code.log\n"
        exit 0
        ;;

    "3")
        list_all_event_type_codes_for_service
        exit 0
        ;;

    "4")
        list_all_event_type_code_for_categories_in_service
        exit 0
        ;;
    *)
        echo "Error : Illegal choice."
        exit 1
        ;;
esac