#!/bin/bash -eux

rpm -Uvh https://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm
yum install -y puppet-agent
for X in $(ls /opt/puppetlabs/bin); do
	ln -sf /opt/puppetlabs/bin/$X /usr/bin/$X
done

mkdir -p /etc/puppetlabs/code/environments
chown -R vagrant:vagrant /etc/puppetlabs/code/environments

