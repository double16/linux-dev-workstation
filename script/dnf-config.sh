#!/bin/bash -eux

set +H

# Ensure docs are installed with packages
sed -i '/tsflags=nodocs/d' /etc/dnf/dnf.conf

if [ -n "$yum_proxy" ] && ! grep -qF 'proxy=' /etc/dnf/dnf.conf && wget -t 1 -O /dev/null "${yum_proxy}acng-report.html"; then
    echo "==> Configuring temporary DNF proxy at $yum_proxy"
    cat >>/etc/dnf/dnf.conf <<EOF
proxy=$yum_proxy
EOF
fi
