#!/bin/bash -eux

USERNAME=${SSH_USERNAME:-vagrant}

if mountpoint "/tmp/vagrant-cache"; then
    echo "==> Configuring cache"
    if [ ! -d /tmp/vagrant-cache/yum ]; then
        mkdir -p /tmp/vagrant-cache/yum
        rsync -r /var/cache/yum/ /tmp/vagrant-cache/yum/
    fi
    rm -rf /var/cache/yum
    ln -sf /tmp/vagrant-cache/yum /var/cache/yum
    sed -i 's/keepcache=0/keepcache=1/g' /etc/yum.conf
    cat >>/etc/yum.conf <<EOF

metadata_expire=90m
mirrorlist_expire=90m
metadata_expire_filter=never
EOF

    mkdir -p /tmp/vagrant-cache/npm
    grep -qF 'cache=' /root/.npmrc || cat >>/root/.npmrc <<EOF
cache=/tmp/vagrant-cache/npm
EOF
    grep -qF 'cache=' /home/${USERNAME}/.npmrc || cat >>/home/${USERNAME}/.npmrc <<EOF
cache=/tmp/vagrant-cache/npm
EOF
fi

if [ -n "$yum_proxy" ] && curl --fail -s -o /dev/null "${yum_proxy}acng-report.html"; then
    echo "==> Configuring temporary Yum proxy at $yum_proxy"
    cat >>/etc/yum.conf <<EOF
proxy=$yum_proxy
EOF
fi
