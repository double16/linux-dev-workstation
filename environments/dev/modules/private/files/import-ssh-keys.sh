#!/bin/bash

#
# Imports user SSH keys into the vagrant user. This script is a Vagrant provisioner. All SSH keys inside /vagrant that include
# a private and public key are configured in /home/vagrant/.ssh/config.
#

SSH_DIR=/home/vagrant/.ssh
SSH_CONFIG="${SSH_DIR}/config"

mkdir -p "${SSH_DIR}"
chown vagrant:vagrant "${SSH_DIR}"
chmod 0700 "${SSH_DIR}"

touch "${SSH_CONFIG}"
chown vagrant:vagrant "${SSH_CONFIG}"
chmod 0644 "${SSH_CONFIG}"

find /vagrant/ \
     \( -path '/vagrant/environments/*' \
     -o -path '/vagrant/.*/*' \) \
     -prune \
     -o -name '*.pub' \
     -type f \
     -print | \
     xargs grep -l "^ssh-" | \
     xargs sha256sum | \
     while read PUBLIC_KEY_HASH PUBLIC_KEY; do

  PRIVATE_KEY="${PUBLIC_KEY/.pub/}"
  PRIVATE_KEY_IN_VM="${SSH_DIR}/${PUBLIC_KEY_HASH}.pem"
  if [ -s "${PRIVATE_KEY}" ] && ! grep -q "IdentityFile \"${PRIVATE_KEY_IN_VM}\"" "${SSH_CONFIG}"; then
    # We can't control the permissions in /vagrant, so copy the key into the VM
    cp "${PRIVATE_KEY}" "${PRIVATE_KEY_IN_VM}"
    chown vagrant:vagrant "${PRIVATE_KEY_IN_VM}"
    chmod 0600 "${PRIVATE_KEY_IN_VM}"
    echo "IdentityFile \"${PRIVATE_KEY_IN_VM}\"" >> "${SSH_CONFIG}"
    echo "Added ${PRIVATE_KEY} to ${SSH_CONFIG}"
  fi

done


