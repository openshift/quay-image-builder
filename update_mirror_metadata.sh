#!/bin/bash -x

# Packer doesn't like braces in shell provisioners and doesn't escape them well
# so this needs to be done in a separate shell

# This converts the output of oc-mirror into an anisble template
# to be used by the replace-quay-certificates.yaml playbook when updating the hostname
# and port of the registry and is run during the packer build process only

TEMPLATE=$(hostname)

# Rename the directory with a consistent name
mv /home/ec2-user/oc-mirror-workspace/results-* /home/ec2-user/oc-mirror-workspace/results

# TODO: Not sure if this dir is always empty
#rmdir /home/ec2-user/oc-mirror-workspace/publish

# Copy the oc-mirror output as ansible template files
if [[ -f /home/ec2-user/oc-mirror-workspace/results/imageContentSourcePolicy.yaml ]]
then
  cp -f /home/ec2-user/oc-mirror-workspace/results/imageContentSourcePolicy.yaml \
        /home/ec2-user/playbooks/templates/imageContentSourcePolicy.yaml.j2
fi

if [[ -f /home/ec2-user/oc-mirror-workspace/results/updateService.yaml ]]
then
  cp -f /home/ec2-user/oc-mirror-workspace/results/updateService.yaml \
        /home/ec2-user/playbooks/templates/updateService.yaml.j2
fi

if [[ -f /home/ec2-user/oc-mirror-workspace/results/mapping.txt ]]
then
  cp -f /home/ec2-user/oc-mirror-workspace/results/mapping.txt \
        /home/ec2-user/playbooks/templates/mapping.txt.j2
fi

if [[ -f /home/ec2-user/oc-mirror-workspace/results/catalogSource-redhat-operator-index.yaml ]]
then
    cp -f /home/ec2-user/oc-mirror-workspace/results/catalogSource-redhat-operator-index.yaml \
          /home/ec2-user/playbooks/templates/catalogSource-redhat-operator-index.yaml.j2
fi

# Mirroring does not currently include certified operators but may in the future
if [[ -f /home/ec2-user/oc-mirror-workspace/results/catalogSource-certified-operator-index.yaml ]]
then
    cp -f /home/ec2-user/oc-mirror-workspace/results/catalogSource-certified-operator-index.yaml \
          /home/ec2-user/playbooks/templates/catalogSource-certified-operator-index.yaml.j2
fi

# Mirroring does not currently include community operators but may in the future
if [[ -f /home/ec2-user/oc-mirror-workspace/results/catalogSource-community-operator-index.yaml ]]
then
    cp -f /home/ec2-user/oc-mirror-workspace/results/catalogSource-community-operator-index.yaml \
          /home/ec2-user/playbooks/templates/catalogSource-community-operator-index.yaml.j2
fi

# Replace the hostname and port of the registry during packer build with template parameters 
sed -i "s|${TEMPLATE}|{{ quay_hostname }}|g" \
  /home/ec2-user/playbooks/templates/imageContentSourcePolicy.yaml.j2

sed -i "s|8443|{{ quay_port }}|g" \
  /home/ec2-user/playbooks/templates/imageContentSourcePolicy.yaml.j2

sed -i "s|${TEMPLATE}|{{ quay_hostname }}|g" \
  /home/ec2-user/playbooks/templates/updateService.yaml.j2

sed -i "s|8443|{{ quay_port }}|g" \
  /home/ec2-user/playbooks/templates/updateService.yaml.j2

sed -i "s|${TEMPLATE}|{{ quay_hostname }}|g" \
  /home/ec2-user/playbooks/templates/mapping.txt.j2

sed -i "s|8443|{{ quay_port }}|g" \
  /home/ec2-user/playbooks/templates/mapping.txt.j2

if [[ -f /home/ec2-user/oc-mirror-workspace/results/catalogSource-redhat-operator-index.yaml ]]
then
  sed -i "s|${TEMPLATE}|{{ quay_hostname }}|g" \
    /home/ec2-user/playbooks/templates/catalogSource-redhat-operator-index.yaml.j2

  sed -i "s|8443|{{ quay_port }}|g" \
    /home/ec2-user/playbooks/templates/catalogSource-redhat-operator-index.yaml.j2
fi

# Mirroring does not currently include certified operators but may in the future
if [[ -f /home/ec2-user/oc-mirror-workspace/results/catalogSource-certified-operator-index.yaml ]]
then
  sed -i "s|${TEMPLATE}|{{ quay_hostname }}|g" \
    /home/ec2-user/playbooks/templates/catalogSource-certified-operator-index.yaml.j2

  sed -i "s|8443|{{ quay_port }}|g" \
    /home/ec2-user/playbooks/templates/catalogSource-certified-operator-index.yaml.j2
fi
# Mirroring does not currently include community operators but may in the future
if [[ -f /home/ec2-user/oc-mirror-workspace/results/catalogSource-community-operator-index.yaml ]]
then
  sed -i "s|${TEMPLATE}|{{ quay_hostname }}|g" \
    /home/ec2-user/playbooks/templates/catalogSource-community-operator-index.yaml.j2

  sed -i "s|8443|{{ quay_port }}|g" \
    /home/ec2-user/playbooks/templates/catalogSource-community-operator-index.yaml.j2
fi

# Remove the unpacked catalog images that are not needed
rm -rf /home/ec2-user/oc-mirror-workspace/src/

exit 0
