#!/bin/bash

cat << EOF > image_pipeline_config.json
{
    "name": "HelloWorldPipeline",
    "description": "Hello World App",
    "enhancedImageMetadataEnabled": true,
    "imageRecipeArn": "$IMAGE_RECIPE_ARN",
    "infrastructureConfigurationArn": "$INFRA_CONF_ARN",
    "distributionConfigurationArn": "$DIST_CONFIG_ARN",
    "imageTestsConfiguration": {
        "imageTestsEnabled": true,
        "timeoutMinutes": 60
    },
    "schedule": {
        "scheduleExpression": "cron(0 8 1 * ? *)",
        "pipelineExecutionStartCondition": "EXPRESSION_MATCH_AND_DEPENDENCY_UPDATES_AVAILABLE"
    },
    "status": "ENABLED"
}
EOF
 
## Create Image pipeline
aws imagebuilder create-image-pipeline --cli-input-json file://image_pipeline_config.json
 
## List all image pipelines
aws imagebuilder list-image-pipelines --filters '[{"name": "name", "values": ["HelloWorldPipeline"]}]'
 
## Get details on the image pipeline
PIPELINE_ARN=$(aws imagebuilder list-image-pipelines \
--filters '[{"name": "name", "values": ["HelloWorldPipeline"]}]' \
--query 'imagePipelineList[].arn' \
--output text)

aws imagebuilder get-image-pipeline --image-pipeline-arn $PIPELINE_ARN
