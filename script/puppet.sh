#!/bin/bash -eux

rpm -Uvh https://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm
yum install -y puppet-agent
for X in $(ls /opt/puppetlabs/bin); do
	ln -sf /opt/puppetlabs/bin/$X /usr/bin/$X
done

# workaround bug in packer 1.1.0, should be fixed in 1.1.1, https://github.com/hashicorp/packer/issues/5347
mkdir -p /tmp/packer-puppet-masterless/manifests
mkdir -p /tmp/packer-puppet-masterless/module-0
chmod -R 777 /tmp/packer-puppet-masterless

