#!/bin/bash -eux

set +H

SSH_USER=${SSH_USERNAME:-vagrant}
echo "==> Configuring permissions for ${SSH_USER}"

[ -d "/opt/puppetlabs" ] && chown -R "${SSH_USER}:${SSH_USER}" /opt/puppetlabs
