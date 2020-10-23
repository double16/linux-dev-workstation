#!/bin/bash -eux

set +H

SSH_USER=${SSH_USERNAME:-vagrant}
echo "==> Configuring permissions for ${SSH_USER}"

[ -d "/opt/puppetlabs" ] && chown -R "${SSH_USER}:${SSH_USER}" /opt/puppetlabs

# When building a container /etc/fstab isn't necessary, but Vagrant may expect it
echo "==> Ensuring /etc/fstab exists"
touch /etc/fstab
