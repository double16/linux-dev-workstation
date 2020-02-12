#!/bin/bash -eux

set +H

# cgroup1 for k3s v1.0.0
if [ -f /boot/grub2/grub.cfg ]; then
    command -v grubby >/dev/null || dnf install -y grubby
    grubby --update-kernel=ALL --args="systemd.unified_cgroup_hierarchy=0"
fi
