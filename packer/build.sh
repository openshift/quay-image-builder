#!/bin/bash -e

export PACKER_TEMPLATE="aws-rhel8-quay.json"

export PULL_SECRET="${PULL_SECRET:-/home/danclark/pull-secret.txt}"

# Use zone c for builds. Change to a different zone for your region if needed
export AWS_ZONE="${AWS_ZONE:-c}"

# Red Hat Account ID in AWS for AMI search
REDHAT_ID="309956199498"

# Current RHEL version to build with
export RHEL_VER="8.6"

export OCP_VER="${OCP_VER:-4.11}"

if [ -z $AWS_ACCESS_KEY_ID ];
then
  echo "AWS_ACCESS_KEY_ID Required"
  exit 1
fi

if [ -z $AWS_SECRET_ACCESS_KEY ];
then
  echo "AWS_SECRET_ACCESS_KEY Required"
  exit 1
fi

if [ -z $AWS_DEFAULT_REGION ];
then
  echo "AWS_DEFAULT_REGION Required"
  exit 1
fi

# Get default VPC ID
export DEFAULT_VPC_ID=$(aws ec2 describe-vpcs \
  --query 'Vpcs[?IsDefault == `true`].VpcId' \
  --output text) 

# Get subnet ID for az ${AWS_ZONE} in region ${AWS_DEFAULT_REGION}
export SUBNET_ID=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=${DEFAULT_VPC_ID}" \
  --query "Subnets[?AvailabilityZone == '${AWS_DEFAULT_REGION}${AWS_ZONE}'].SubnetId" \
  --output text)

#export SOURCE_AMI=$(aws ec2 describe-images --owners ${REDHAT_ID} --region ${AWS_DEFAULT_REGION} \
#  --output text --query 'Images[*].[ImageId]' \
#  --filters "Name=name,Values=RHEL-${RHEL_VER}?*HVM-*Hourly*" Name=architecture,Values=x86_64 | sort -r)
export SOURCE_AMI="ami-063851ca4aec10974"

export AWS_MAX_ATTEMPTS="120"
export AWS_POLL_DELAY_SECONDS="60"

packer build ${PACKER_TEMPLATE} | tee packer.log

exit 0
