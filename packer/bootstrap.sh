#!/bin/bash

echo "Bootstrap script..."
# Enter any additional commands or package installs here

# Install updates
sudo dnf -y update

# Install ansible
sudo dnf -y install ansible

# Pull OCP Dependencies
curl -O -L "https://developers.redhat.com/content-gateway/file/pub/openshift-v4/clients/mirror-registry/1.2.6/mirror-registry.tar.gz"
curl -O -L "https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/latest-4.11/openshift-install-linux.tar.gz"
curl -O -L "https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/latest-4.11/openshift-client-linux.tar.gz"

tar -xzf openshift-install-linux.tar.gz
tar -xzf openshift-client-linux.tar.gz
tar -xzf mirror-registry.tar.gz
rm -f openshift-install-linux.tar.gz  
sudo cp openshift-install oc kubectl /usr/local/bin/
pushd /usr/local/bin
sudo chown root.root openshift-install oc kubectl
sudo chmod 0755 openshift-install oc kubectl
sudo restorecon -v openshift-install oc kubectl
popd

exit 0
