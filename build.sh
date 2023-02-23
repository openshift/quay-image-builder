#!/bin/bash -e

DEF_OCP_VER=4.11.8

export PACKER_TEMPLATE="aws-rhel8-quay.json"
export PULL_SECRET="${PULL_SECRET:-${HOME}/pull-secret.txt}"

# Use zone c for builds. Change to a different zone for your region if needed
export AWS_ZONE="${AWS_ZONE:-c}"

# Red Hat Account ID in AWS for AMI search
export REDHAT_ID="${REDHAT_ID:-309956199498}"

# Current RHEL version to build with
export RHEL_VER="${RHEL_VER:-8.6}"

# Full OpenShift Version; i.e 4.11.8
export OCP_VER="${OCP_VER:-${DEF_OCP_VER}}"

# Major OpenShift Version; i.e 4.11
export OCP_MAJ_VER=$(echo "${OCP_VER}" | awk -F\. '{print $1"."$2}')

# By default these are equal which mirrors a single OpenShift Version
# Setting them to different values; i.e 4.11.1 and 4.11.5
# will cause the AMI to include the OpenShift Images for all versions
# from 4.11.1 through 4.11.5 inclusive
export OCP_MIN_VER="${OCP_MIN_VER:-${OCP_VER}}"
export OCP_MAX_VER="${OCP_MAX_VER:-${OCP_VER}}"

# AWS EIP Configuration
export USER_DATA_FILE="cloud-config.sh"
# Example AWS EIP allocation ID
#export EIP_ALLOC=eipalloc-abc123

# The IAM instance profile needs to have permissions to associate an EIP with an instance
export IAM_INSTANCE_PROFILE="${IAM_INSTANCE_PROFILE:-packer}"

# Logging statements
echo OCP_VER=${OCP_VER}
echo OCP_MAJ_VER=${OCP_MAJ_VER}
echo OCP_MIN_VER=${OCP_MIN_VER}
echo OCP_MAX_VER=${OCP_MAX_VER}

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

if [ -z $EIP_ALLOC ];
then
  echo "EIP_ALLOC Required"
  exit 1
fi

# Obtain the IP address associated with the EIP Allocation ID
echo "Get EIP Address"
export EIP_ADDRESS=$(aws ec2 describe-addresses --allocation-ids ${EIP_ALLOC} | jq -r '.Addresses[0].PublicIp')
rm -f "${USER_DATA_FILE}"
sed "s|eipalloc-abc123|${EIP_ALLOC}|g" cloud-config.sh.template > "${USER_DATA_FILE}"
sed -e '/CDN_PEM_CONTENT/ {' -e 'r rh-cdn.pem' -e 'd' -e '}' -i "${USER_DATA_FILE}"
sed -e '/YUM_REPO_CONTENT/ {' -e 'r quay_image.repo' -e 'd' -e '}' -i "${USER_DATA_FILE}"
sed -i "s|OCP_MAJ_VER|${OCP_MAJ_VER}|g" "${USER_DATA_FILE}"

chmod 0755 cloud-config.sh

if [ -z $DEFAULT_VPC_ID ];
then
  # Get default VPC ID
  export DEFAULT_VPC_ID=$(aws ec2 describe-vpcs \
    --query 'Vpcs[?IsDefault == `true`].VpcId' \
    --output text)
fi

if [ -z $SUBNET_ID ];
then
  # Get subnet ID for az ${AWS_ZONE} in region ${AWS_DEFAULT_REGION}
  export SUBNET_ID=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=${DEFAULT_VPC_ID}" \
    --query "Subnets[?AvailabilityZone == '${AWS_DEFAULT_REGION}${AWS_ZONE}'].SubnetId" \
    --output text)
fi

if [ -z $SOURCE_AMI ];
then
  export SOURCE_AMI=$(aws ec2 describe-images --owners ${REDHAT_ID} --region ${AWS_DEFAULT_REGION} \
    --output text --query 'Images[*].[ImageId]' \
    --filters "Name=name,Values=RHEL-${RHEL_VER}?*HVM-*Hourly*" Name=architecture,Values=x86_64 | sort -r | head -1)
fi

# Need to set these values or packer can timeout due to how long
# it can take for the AMI to become ready in the AWS API/Console
export AWS_MAX_ATTEMPTS="240"
export AWS_POLL_DELAY_SECONDS="30"
export PACKER_ARGS=""
export SSH_TIMEOUT="6m"

if [[ "${PACKER_DEBUG}" == "true" ]]; then
  PACKER_ARGS="-debug"
  export SSH_TIMEOUT="30m"
  echo "RUNNING IN DEBUG MODE; SSH TIMEOUT IS SET TO 30m TO ALLOW REMOTE ANALYSIS"
  echo "PACKER WILL WRITE SSH KEYS TO WORKSPACE"
fi


/usr/bin/packer build ${PACKER_ARGS} -machine-readable ${PACKER_TEMPLATE} | tee packer.log

exit 0
