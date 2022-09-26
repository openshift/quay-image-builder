#!/bin/bash -e

export PACKER_TEMPLATE="aws-rhel8-quay.json"

export PULL_SECRET="/home/danclark/pull-secret.txt"

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

export DEFAULT_VPC_ID=$(aws ec2 describe-vpcs \
  --query 'Vpcs[?IsDefault == `true`].VpcId' \
  --output text) 

export SUBNET_ID=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=${DEFAULT_VPC_ID}" \
  --query 'Subnets[?AvailabilityZone == `us-east-1c`].SubnetId' \
  --output text)

export SOURCE_AMI=$(aws ec2 describe-images --owners 309956199498 --region us-east-1 \
  --output text --query 'Images[*].[ImageId]' \
  --filters "Name=name,Values=RHEL-8.6?*HVM-*Hourly*" Name=architecture,Values=x86_64 | sort -r)

ansible-galaxy role install redhatofficial.rhel8_stig

packer build ${PACKER_TEMPLATE} | tee packer.log

exit 0
