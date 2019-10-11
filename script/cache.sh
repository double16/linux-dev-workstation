#!/bin/bash -eux

set +H

USERNAME=${SSH_USERNAME:-vagrant}
SSH_USER=${SSH_USERNAME:-vagrant}
SSH_USER_HOME=${SSH_USER_HOME:-/home/${SSH_USER}}

if [[ $PACKER_BUILDER_TYPE =~ virtualbox ]] && ! mountpoint "/tmp/vagrant-cache" 2>/dev/null; then
    echo "==> Mounting shared folder vagrant-cache to /tmp/vagrant-cache"
    mkdir -p /tmp/vagrant-cache
    mount -t vboxsf -o rw,nodev,uid=${SSH_USER},gid=${SSH_USER} vagrant-cache /tmp/vagrant-cache || true
fi

if mountpoint "/tmp/vagrant-cache"; then
    echo "==> Configuring cache"
    mkdir -p /tmp/vagrant-cache/dnf
    touch /tmp/vagrant-cache/dnf/works
    if ln -sf /tmp/vagrant-cache/dnf/works /tmp/vagrant-cache/dnf/works.lnk; then
        rsync -r /var/cache/dnf/ /tmp/vagrant-cache/dnf/
        rm -rf /var/cache/dnf
        ln -sf /tmp/vagrant-cache/dnf /var/cache/dnf
        sed -i 's/keepcache=0/keepcache=1/g' /etc/dnf/dnf.conf
    else
        echo "==> Symlinks not supported, skipping DNF cache"
    fi

    mkdir -p /tmp/vagrant-cache/npm /tmp/vagrant-cache/npm_${USERNAME}
    chgrp -R wheel /tmp/vagrant-cache/npm /tmp/vagrant-cache/npm_${USERNAME}
    find /tmp/vagrant-cache/npm /tmp/vagrant-cache/npm_${USERNAME} -type d | xargs -r chmod g+rws
    grep -qF 'cache=' /root/.npmrc 2>/dev/null || cat >>/root/.npmrc <<EOF
cache=/tmp/vagrant-cache/npm
EOF
    grep -qF 'cache=' /home/${USERNAME}/.npmrc 2>/dev/null || cat >>/home/${USERNAME}/.npmrc <<EOF
cache=/tmp/vagrant-cache/npm_${USERNAME}
EOF
    chown ${USERNAME}:${USERNAME} /home/${USERNAME}/.npmrc

fi
