#!/bin/bash -e

# URIs to make scripts lines shorter
DEV_URI="https://developers.redhat.com/content-gateway/file/pub/openshift-v4/clients"
MIRROR_URI="https://mirror.openshift.com/pub/openshift-v4/x86_64/clients"

OCP_VER="4.11"

echo "Bootstrap script..."
# Enter any additional commands or package installs here

#dnf clean all

# TODO: Commented out for testing
# Install updates
#dnf -y update

# Install ansible
dnf -y install ansible podman firewalld git vim python3 jq
systemctl enable --now firewalld

# Upgrade pip
pip3 install --upgrade pip

# TODO: Add hardening 
#ansible-playbook /tmp/harden_quay.yaml

# Pull OCP Dependencies
curl -O -L "${DEV_URI}/mirror-registry/1.2.6/mirror-registry.tar.gz"
curl -O -L "${MIRROR_URI}/ocp/latest-${OCP_VER}/openshift-install-linux.tar.gz"
curl -O -L "${MIRROR_URI}/ocp/latest-${OCP_VER}/openshift-client-linux.tar.gz"
curl -O -L "${MIRROR_URI}/ocp/latest-${OCP_VER}/oc-mirror.tar.gz"
curl -O -L "${MIRROR_URI}/pipeline/latest/tkn-linux-amd64.tar.gz"
curl -O -L "${DEV_URI}/odo/v2.5.1/odo-linux-amd64"

tar -xzf openshift-install-linux.tar.gz
tar -xzf openshift-client-linux.tar.gz
tar -xzf oc-mirror.tar.gz
tar -xzf tkn-linux-amd64.tar.gz
mv -f openshift-install oc kubectl oc-mirror tkn tkc-pac odo-linux-amd64 /usr/local/bin/
pushd /usr/local/bin
chown root.root openshift-install oc kubectl oc-mirror tkn tkc-pac odo-linux-amd64
chmod 0755 openshift-install oc kubectl oc-mirror tkn tkc-pac odo-linux-amd64
restorecon -v openshift-install oc kubectl oc-mirror tkn tkc-pac odo-linux-amd64
popd

# Mirror registry setup
tar -xzf mirror-registry.tar.gz
mkdir -p /opt/quay || true
./mirror-registry install --verbose --quayRoot /opt/quay/ | tee mirror-registry.log
mv mirror-registry /usr/local/bin/mirror-registry
restorecon -v /usr/local/bin/mirror-registry

# Add quay certificate to the trust store
rm -f /etc/pki/ca-trust/source/anchors/quay.cert
cp /opt/quay/quay-config/ssl.cert /etc/pki/ca-trust/source/anchors/quay.cert
chmod 0644 /etc/pki/ca-trust/source/anchors/quay.cert
restorecon -v /etc/pki/ca-trust/source/anchors/quay.cert
update-ca-trust
update-ca-trust extract


# Cleanup
# TODO: For testing, don't remove files
#rm -f openshift-install-linux.tar.gz
#rm -f openshift-client-linux.tar.gz
#rm -f oc-mirror.tar.gz
#rm -f tkn-linux-amd64.tar.gz
#rm -f README.md
#rm -f mirror-registry.tar.gz
#rm -f execution-environment.tar
#rm -f image-archive.tar
#rm -f pause.tar
#rm -f postgres.tar
#rm -f quay.tar
#rm -f redis.tar

exit 0
