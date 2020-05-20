#!/bin/bash -ux

set +H

SSH_USER=${SSH_USERNAME:-vagrant}
SSH_USER_HOME=${SSH_USER_HOME:-/home/${SSH_USER}}

if [[ ${PACKER_BUILDER_TYPE} =~ 'docker' ]]; then
    dnf reinstall -y glibc-common
    dnf install -y glibc-locale-source glibc-langpack-en
    localedef -f UTF-8 -i en_US en_US.utf8
    echo "LANG=en_US.utf8" > /etc/locale.conf
    echo "LANGUAGE=en_US:en" >> /etc/locale.conf
    echo "LC_ALL=en_US.utf8" >> /etc/locale.conf
    cp /etc/locale.conf /etc/sysconfig/i18n
fi

if [[ $UPDATE  =~ true || $UPDATE =~ 1 || $UPDATE =~ yes ]]; then
    echo "==> Applying updates"
    dnf -y update || exit $?

    # reboot
    echo "==> Rebooting the machine..."
    reboot
    sleep 60
fi
