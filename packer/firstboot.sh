#!/bin/bash

echo "Update imageset config"
sed -i "s|ip-.*-.*-.*-.*.ec2.internal|${HOSTNAME}|g" /tmp/imageset-config.yaml

pushd /tmp/playbooks/

echo "Replace quay SSL certificates"
ansible-playbook replace-quay-certificates.yaml

popd

exit 0
