#!/bin/bash -e

OCP_VER="4.11"

echo "Bootstrap script..."
# Enter any additional commands or package installs here

#sudo dnf clean all

# TODO: Commented out for testing
# Install updates
#sudo dnf -y update

# Install ansible
sudo dnf -y install ansible

# Install ansibl roles
ansible-galaxy role install redhatofficial.rhel8_stig

#ansible-playbook /tmp/harden_quay.yaml

# Pull OCP Dependencies
curl -O -L "https://developers.redhat.com/content-gateway/file/pub/openshift-v4/clients/mirror-registry/1.2.6/mirror-registry.tar.gz"
curl -O -L "https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/latest-${OCP_VER}/openshift-install-linux.tar.gz"
curl -O -L "https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/latest-${OCP_VER}/openshift-client-linux.tar.gz"
curl -O -L "https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/latest-${OCP_VER}/oc-mirror.tar.gz"

tar -xzf openshift-install-linux.tar.gz
tar -xzf openshift-client-linux.tar.gz
tar -xzf mirror-registry.tar.gz
tar -xzf oc-mirror.tar.gz
rm -f openshift-install-linux.tar.gz  
rm -f openshift-client-linux.tar.gz
rm -f oc-mirror.tar.gz
rm -f README.md
sudo mv -f openshift-install oc kubectl oc-mirror /usr/local/bin/
pushd /usr/local/bin
sudo chown root.root openshift-install oc kubectl oc-mirror
sudo chmod 0755 openshift-install oc kubectl oc-mirror
sudo restorecon -v openshift-install oc kubectl oc-mirror
popd

sudo dnf -y install podman firewalld
sudo systemctl enable --now firewalld

sudo mkdir /opt/quay
sudo ./mirror-registry install --verbose --quayRoot /opt/quay/ | tee mirror-registry.log

USER=$(grep -Pzo credentials.* log | sed 's|credentials ||' | tr -d ' ' | tr -d '(' | tr -d ')' | awk -F\, '{print $1}')
PASS=$(grep -Pzo credentials.* log | sed 's|credentials ||' | tr -d ' ' | tr -d '(' | tr -d ')' | awk -F\, '{print $2}')
podman login --tls-verify=false -u=${USER} -p=${PASS} localhost:8443

oc-mirror --config /tmp/imageset-config.yaml --dest-skip-tls --continue-on-error docker://localhost:8443

exit 0
