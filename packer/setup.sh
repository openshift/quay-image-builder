#!/bin/bash -e

# Install ansible roles
ansible-galaxy role install redhatofficial.rhel8_stig

git clone https://github.com/RedHatGov/openshift4-c2s.git

pip3 install --user wheel jinja2 awscli

ansible-galaxy collection install amazon.aws community.aws community.crypto

mkdir -p "${XDG_RUNTIME_DIR}/containers/" || true
cp /tmp/pull-secret.txt "${XDG_RUNTIME_DIR}/containers/auth.json"

REG_USER=$(grep -o credentials.* mirror-registry.log | sed 's|credentials ||' | tr -d ' ' | tr -d '"' | tr -d '(' | tr -d ')' | awk -F\, '{print $1}' | tr -d '\n')

REG_PASS=$(grep -o credentials.* mirror-registry.log | sed 's|credentials ||' | tr -d ' ' | tr -d '"' | tr -d '(' | tr -d ')' | awk -F\, '{print $2}' | tr -d '\n')

podman login --tls-verify=false -u=${REG_USER} -p=${REG_PASS} localhost:8443
podman login --tls-verify=false -u=${REG_USER} -p=${REG_PASS} ${HOSTNAME}:8443

# Don't use localhost in the mirror config
sed -i "s|localhost|${HOSTNAME}|g" /tmp/imageset-config.yaml

#/usr/local/bin/oc-mirror --config /tmp/imageset-config.yaml --dest-skip-tls --continue-on-error docker://${HOSTNAME}:8443

#rm -f "${XDG_RUNTIME_DIR}/containers/auth.json"

exit 0
