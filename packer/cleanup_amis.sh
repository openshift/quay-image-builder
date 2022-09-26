#!/bin/bash

# Cleanup AMIs and Snapshots of builds

while read -r line
do

  AMI=$(echo "${line}" | awk '{print $1}')
  SNAP=$(echo "${line}" | awk '{print $2}')

  echo "Removing AMI: ${AMI}"
  aws ec2 deregister-image --image-id ${AMI}
  # Wait for deregister to cleanup snapshot
  sleep 5
  echo "Removing Snapshot: ${SNAP}"
  aws ec2 delete-snapshot --snapshot-id ${SNAP}

done < <(aws ec2 describe-images --owners self --output json | jq '.Images[] | select(.Description | startswith("Quay")) ' | jq -r '"\(.ImageId) \(.BlockDeviceMappings[0].Ebs.SnapshotId)"')

exit 0
