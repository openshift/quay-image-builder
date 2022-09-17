#!/bin/bash

KEY_PAIR="danclark-personal"

## Get default VPC, Subnet and SG id
DEAFULT_VPC_ID=$(aws ec2 describe-vpcs \
--query 'Vpcs[?IsDefault == `true`].VpcId' \
--output text) 

echo "Default VPC: $DEAFULT_VPC_ID"

SUBNET_ID=$(aws ec2 describe-subnets \
--query 'Subnets[?AvailabilityZone == `ap-south-1a`].SubnetId' \
--output text)

echo "Subnet: $SUBNET_ID"

DEFAULT_SECURITY_GROUP_ID=$(aws ec2 describe-security-groups \
--filters "Name=vpc-id,Values=$DEAFULT_VPC_ID" \
--query 'SecurityGroups[?GroupName == `default`].GroupId' \
--output text) 

echo "Default SG: $DEFAULT_SECURITY_GROUP_ID"
 
## Create infrastructure configuration file
cat << EOF > image_infra_config.json
{
    "name": "HelloWorldInfrastructure",
    "description": "Hello World App",
    "instanceTypes": [
        "t2.micro"
    ],
    "instanceProfileName": "HelloWorldInstanceProfile",
    "securityGroupIds": [
        "$DEFAULT_SECURITY_GROUP_ID"
    ],
    "subnetId": "$SUBNET_ID",
    "logging": {
        "s3Logs": {
            "s3BucketName": "cloudaffaire-image-builder",
            "s3KeyPrefix": "Logs"
        }
    },
    "keyPair": "${KEY_PAIR}",
    "terminateInstanceOnFailure": true
}
EOF
 
## Create infrastructure configuration
aws imagebuilder create-infrastructure-configuration \
--cli-input-json file://image_infra_config.json
 
## List all infrastructure configurations
aws imagebuilder list-infrastructure-configurations
 
## Get details on Infrastructure configuration
INFRA_CONF_ARN=$(aws imagebuilder list-infrastructure-configurations | jq -r .infrastructureConfigurationSummaryList[].arn) &&
aws imagebuilder get-infrastructure-configuration \
--infrastructure-configuration-arn $INFRA_CONF_ARN
