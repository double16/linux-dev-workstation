#!/bin/bash -eux

set +H

SSH_USER=${SSH_USERNAME:-vagrant}
SSH_USER_HOME=${SSH_USER_HOME:-/home/${SSH_USER}}

if [[ ${PACKER_BUILDER_TYPE} =~ 'docker' ]]; then
    # Need this to get back the UTF-8 locale
    yum -y install glibc-common || yum -y reinstall glibc-common
    yum -y remove ius-release
fi

if [[ $UPDATE  =~ true || $UPDATE =~ 1 || $UPDATE =~ yes ]]; then
    if [[ $PACKER_BUILDER_TYPE =~ virtualbox ]]; then
        VBOX_VERSION=$(cat $SSH_USER_HOME/.vbox_version)
        if [ ${VBOX_VERSION/.*/} -lt 6 ]; then
            echo "==> Disabling kernel upgrades for VirtualBox < 6"
            echo "exclude=kernel*" >> /etc/yum.conf
        fi
    fi

    echo "==> Applying updates"
    yum -y update

    # reboot
    echo "Rebooting the machine..."
    reboot
    sleep 60
fi
