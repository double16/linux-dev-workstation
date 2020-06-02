#!/bin/bash -eux

set +H -ux

rpm -Uvh https://yum.puppet.com/puppet6-release-fedora-31.noarch.rpm
dnf --verbose install -y puppet-agent-6.15.0-1.fc31.x86_64
for X in $(ls /opt/puppetlabs/bin); do
	ln -sf /opt/puppetlabs/bin/$X /usr/bin/$X
done

SSH_USER=${SSH_USERNAME:-vagrant}
REAL_USER=${SUDO_USER:-vagrant}
mkdir -p /etc/puppetlabs/code/environments
chown -R ${REAL_USER}:${SSH_USER} /etc/puppetlabs/code/environments
chmod 0775 /etc/puppetlabs/code/environments
