#!/bin/bash -xe

BUCKET_NAME="danclark-image-builder"
COMPONENT_CONFIG="component_config.yaml"
IMAGE_COMPONENT_CONFIG="image_component_config.json"
IMAGE_RECIPE_CONFIG="image_recipe_config.json"

## Upload component document in S3 bucket
aws s3 cp ${COMPONENT_CONFIG} s3://${BUCKET_NAME}/${COMPONENT_CONFIG}
 
## Create custom component config def
cat << EOF > ${IMAGE_COMPONENT_CONFIG}
{
    "name": "RegistryComponent",
    "semanticVersion": "1.0.0",
    "description": "Quay Registry",
    "changeDescription": "Initial version.",
    "platform": "Linux",
    "uri": "s3://${BUCKET_NAME}/${COMPONENT_CONFIG}",
    "tags": {
        "App": "Quay Registry"
    }
}
EOF
 
## Create the custom component
aws imagebuilder create-component --cli-input-json file://${IMAGE_COMPONENT_CONFIG}

## List all available components owned by You
# It takes time for the list to update so keep checking
LINES=0
while [ $LINES -lt 5 ]; do
  sleep 2
  LINES=$(aws imagebuilder list-components --owner Self | wc -l)
done

## List component build version
COMPONENT_VERSION_ARN=$(aws imagebuilder list-components --owner Self | jq -r '.componentVersionList[].arn')

echo "Component ARN: $COMPONENT_VERSION_ARN"

COMPONENT_BUILD_VERSION_ARN=$(aws imagebuilder list-component-build-versions --component-version-arn $COMPONENT_VERSION_ARN | jq -r '.componentSummaryList[].arn')

echo "Component Build ARN: $COMPONENT_BUILD_VERSION_ARN"

aws imagebuilder list-component-build-versions --component-version-arn $COMPONENT_VERSION_ARN
 
## Get custom component details
aws imagebuilder get-component --component-build-version-arn $COMPONENT_BUILD_VERSION_ARN

##########

RHEL_AMI_ID=$(aws ec2 describe-images --owners 309956199498 --region us-east-1 \
    --output text --query 'Images[*].[ImageId]' --filters "Name=name,Values=RHEL-8.6?*HVM-*Hourly*" Name=architecture,Values=x86_64 \
    | sort -r)

echo "RHEL AMI ID: ${RHEL_AMI_ID}"

############

## Create a image recipe document
cat << EOF > ${IMAGE_RECIPE_CONFIG}
{
    "name": "QuayRegistryRecipe",
    "description": "Quay Registry App",
    "semanticVersion": "2019.12.03",
    "components":
    [
        {
            "componentArn": "$COMPONENT_VERSION_ARN"
        }
    ],
    "parentImage": "${RHEL_AMI_ID}"
}
EOF

##############

## Create a custom image recipe
aws imagebuilder create-image-recipe --cli-input-json file://${IMAGE_RECIPE_CONFIG}
