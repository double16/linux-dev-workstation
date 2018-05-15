#!/bin/bash -eux

if [ -d "/tmp/vagrant-cache/yum" ]; then
    echo "==> Configuring cache"
    rm -rf /var/cache/yum
    ln -sf /tmp/vagrant-cache/yum /var/cache/yum
    sed -i 's/keepcache=0/keepcache=1/g' /etc/yum.conf
fi

