#!/bin/bash -ux

set +H

SSH_USER=${SSH_USERNAME:-vagrant}
SSH_USER_HOME=${SSH_USER_HOME:-/home/${SSH_USER}}

if [[ ${PACKER_BUILDER_TYPE} =~ 'docker' ]]; then
    dnf -y install glibc-langpack-en
fi

if [[ $UPDATE  =~ true || $UPDATE =~ 1 || $UPDATE =~ yes ]]; then
    echo "==> Applying updates"
    dnf -y update || exit $?

    # reboot
    echo "==> Rebooting the machine..."
    reboot
    sleep 60
fi
