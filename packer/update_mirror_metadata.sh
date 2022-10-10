#!/bin/bash -x

# Packer doesn't like braces in shell provisioners and doesn't escape them well
# so this needs to be done in a separate shell

sed "s|$(hostname)|{{ quay_hostname }}|g" \
  /home/ec2-user/oc-mirror-workspace/results-*/imageContentSourcePolicy.yaml > \
  /tmp/playbooks/templates/imageContentSourcePolicy.yaml.j2

sed "s|$(hostname)|{{ quay_hostname }}|g" \
  /home/ec2-user/oc-mirror-workspace/results-*/updateService.yaml > \
  /tmp/playbooks/templates/updateService.yaml.j2

sed "s|$(hostname)|{{ quay_hostname }}|g" \
  /home/ec2-user/oc-mirror-workspace/results-*/mapping.txt > \
  /tmp/playbooks/templates/mapping.txt.j2

