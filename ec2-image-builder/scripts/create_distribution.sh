#!/bin/bash

cat << EOF > image_distribution_config.json
{
    "name": "HelloWorldDistribution",
    "description": "Hello World App",
    "distributions": [
        {
            "region": "ap-south-1",
            "amiDistributionConfiguration": {
                "name": "Name {{imagebuilder:buildDate}}",
                "description": "Hello World AMI",
                "amiTags": {
                    "Name": "HelloWorld"
                },
                "launchPermission": {
                    "userIds": [
                        "$ACCOUNT_ID"
                    ]
                }
            }
        }
    ]
}
EOF
 
## Create an Image Distribution Configuration
aws imagebuilder create-distribution-configuration --cli-input-json file://image_distribution_config.json
 
## List all distribution configurations
aws imagebuilder list-distribution-configurations
 
## Get distribution configuration details
DIST_CONFIG_ARN=$(aws imagebuilder list-distribution-configurations | jq -r '.distributionConfigurationSummaryList[].arn')

aws imagebuilder get-distribution-configuration --distribution-configuration-arn $DIST_CONFIG_ARN
