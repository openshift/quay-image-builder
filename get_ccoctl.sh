#!/bin/bash -xe

RELEASE_IMAGE=$(openshift-install version | awk '/release image/ {print $3}')

CCO_IMAGE=$(oc adm release info --image-for='cloud-credential-operator' $RELEASE_IMAGE)

oc image extract $CCO_IMAGE --file="/usr/bin/ccoctl" -a /tmp/pull-secret.txt

sudo mv ccoctl /usr/local/bin
sudo chown root.root /usr/local/bin/ccoctl
sudo chmod 0755 /usr/local/bin/ccoctl
sudo restorecon -v /usr/local/bin/ccoctl

exit 0
