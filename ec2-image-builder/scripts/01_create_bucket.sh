#!/bin/bash -xe

BUCKET_NAME="danclark-image-builder"

# Create an S3 bucket
aws s3api create-bucket \
--bucket ${BUCKET_NAME} \
 
## Get S3 bucket ARN and AWS Account ID and ARN
S3_BUCKET_ARN="arn:aws:s3:::${BUCKET_NAME}"
ACCOUNT_ARN=$(aws sts get-caller-identity | jq -r .Arn)
ACCOUNT_ID=$(aws sts get-caller-identity | jq -r .Account)
 
## Create a s3 bucket policy definition file
cat << EOF > bucket_policy_config.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "ImageBuilderPolicy",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:*",
            "Resource": ["$S3_BUCKET_ARN/*"],
            "Condition": {
                "StringEquals": {
                    "aws:SourceAccount": "$ACCOUNT_ID",
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        }
    ]
}
EOF

## Create a s3 bucket policy
aws s3api put-bucket-policy \
--bucket ${BUCKET_NAME} \
--policy file://bucket_policy_config.json

