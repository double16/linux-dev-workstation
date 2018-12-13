#!/bin/bash -eux

if [ -d "/tmp/vagrant-cache" ]; then
    echo "==> Configuring cache"
    mkdir -p /tmp/vagrant-cache/yum
    rm -rf /var/cache/yum
    ln -sf /tmp/vagrant-cache/yum /var/cache/yum
    sed -i 's/keepcache=0/keepcache=1/g' /etc/yum.conf
    cat >>/etc/yum.conf <<EOF

metadata_expire=90m
mirrorlist_expire=90m
metadata_expire_filter=never
EOF
fi

if [ -n "$yum_proxy" ] && curl --fail -s -o /dev/null "${yum_proxy}acng-report.html"; then
    echo "==> Configuring temporary Yum proxy at $yum_proxy"
    cat >>/etc/yum.conf <<EOF
proxy=$yum_proxy
EOF
fi
