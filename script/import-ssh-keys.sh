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

find /vagrant/ -iname '*.pub' \
     -a -type f \
     -a -not -path '/vagrant/environments/*' \
     -a -not -path '/vagrant/.*/*' \
     -print | \
     xargs -L 1 grep -l "^ssh-" | \
     while read PUBLIC_KEY; do

  PRIVATE_KEY="${PUBLIC_KEY/.pub/}"
  if [ -s "${PRIVATE_KEY}" ] && ! grep -q "IdentityFile \"${PRIVATE_KEY}\"" "${SSH_CONFIG}"; then
    echo "IdentityFile \"${PRIVATE_KEY}\"" >> "${SSH_CONFIG}"
    echo "Added ${PRIVATE_KEY} to ${SSH_CONFIG}"
  fi

done


