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
    grep -qF 'metadata_expire=' /etc/yum.conf || cat >>/etc/yum.conf <<EOF

metadata_expire=90m
mirrorlist_expire=90m
metadata_expire_filter=never
EOF

    mkdir -p /tmp/vagrant-cache/npm /tmp/vagrant-cache/npm_${USERNAME}
    chgrp -R wheel /tmp/vagrant-cache/npm /tmp/vagrant-cache/npm_${USERNAME}
    find /tmp/vagrant-cache/npm /tmp/vagrant-cache/npm_${USERNAME} -type d | xargs -r chmod g+rws
    grep -qF 'cache=' /root/.npmrc 2>/dev/null || cat >>/root/.npmrc <<EOF
cache=/tmp/vagrant-cache/npm
EOF
    grep -qF 'cache=' /home/${USERNAME}/.npmrc 2>/dev/null || cat >>/home/${USERNAME}/.npmrc <<EOF
cache=/tmp/vagrant-cache/npm_${USERNAME}
EOF

fi

if [ -n "$yum_proxy" ] && ! grep -qF 'proxy=' /etc/yum.conf && curl --fail -s -o /dev/null "${yum_proxy}acng-report.html"; then
    echo "==> Configuring temporary Yum proxy at $yum_proxy"
    cat >>/etc/yum.conf <<EOF
proxy=$yum_proxy
EOF
fi
