#!/bin/bash -xe

LOG_FILE="/var/log/mirror-registry.log"

echo "$(date) : Starting the quay firstboot script..." >> "${LOG_FILE}"
chmod 0644 "${LOG_FILE}"

echo "$(date) : Installing quay mirror registry..." >> "${LOG_FILE}"

# Set the HOME env var missing in systemd
export HOME="/root"
export USER="root"

# STIG hardening makes the umask for root 0077
# quay mirror registry will fail to launch when installed with umask 0077
# Make current session and all other sessions for root use umask 0022
# as ansible may cause other login sessions we need to add it to /root/.bashrc
echo 'umask 0022' >> /root/.bashrc
umask 0022
/usr/local/bin/mirror-registry install --verbose --quayRoot /opt/quay/ | tee -a "${LOG_FILE}"

echo "$(date) : Completed install of quay mirror registry" >> "${LOG_FILE}"

# Remove any existing quay certificate
rm -f /etc/pki/ca-trust/source/anchors/quay.cert
# Import quay certificate generated during install
cp -f /opt/quay/quay-config/ssl.cert /etc/pki/ca-trust/source/anchors/quay.cert
chown root.root /etc/pki/ca-trust/source/anchors/quay.cert
chmod 0444 /etc/pki/ca-trust/source/anchors/quay.cert
restorecon -v /etc/pki/ca-trust/source/anchors/quay.cert
update-ca-trust
update-ca-trust extract

echo "$(date) : Updated system certificate trust store" >> "${LOG_FILE}"

# extract the random username and password created by the quay mirror registry installer
export REG_USER=$(grep -o '(.*, .*)' "${LOG_FILE}" | sed 's|[(),]||g' | awk '{print $1}')
export REG_PASS=$(grep -o '(.*, .*)' "${LOG_FILE}" | sed 's|[(),]||g' | awk '{print $2}')

# Create a local copy of the auth file for the ec2-user
podman login --authfile=/home/ec2-user/pull-secret.txt -u=${REG_USER} -p=${REG_PASS} ${HOSTNAME}:8443
chown ec2-user.ec2-user /home/ec2-user/pull-secret.txt
chmod 0644 /home/ec2-user/pull-secret.txt

# Login to local quay registry
mkdir ${HOME}/.docker || true
podman login --authfile=${HOME}/.docker/config.json -u=${REG_USER} -p=${REG_PASS} ${HOSTNAME}:8443

echo "$(date) : Importing local content archive into quay mirror registry..." >> "${LOG_FILE}"

/usr/local/bin/oc-mirror --from /home/ec2-user/archives/mirror_seq1_000000.tar docker://${HOSTNAME}:8443 | tee -a "${LOG_FILE}"

echo "$(date) : Completed import of local content archive" >> "${LOG_FILE}"

# Ensure quay init does not run again
touch /etc/sysconfig/rh-quay-firstboot

# Set the default umask back
sed -i '/umask.*/d' /root/.bashrc

echo "$(date) : Completed the quay firstboot script" >> "${LOG_FILE}"

exit 0
