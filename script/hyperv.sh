#!/bin/bash -eux

set +H

SSH_USER=${SSH_USERNAME:-vagrant}
SSH_USER_HOME=${SSH_USER_HOME:-/home/${SSH_USER}}

if [[ $PACKER_BUILDER_TYPE =~ hyperv && -n "${PACKER_HOST}" && -n "${PACKER_USER}" && -n "${PACKER_PASSWORD}" ]]; then
    echo "==> Mounting /tmp/vagrant-cache"
    mkdir -p /tmp/vagrant-cache
    mount -t cifs -o "rw,nodev,vers=2.0,cache=strict,forceuid,forcegid,addr=${PACKER_HOST},soft,nounix,serverino,mapposix,nobrl,actimeo=1,uid=${SSH_USER},gid=${SSH_USER},username=${PACKER_USER},password=${PACKER_PASSWORD}" //${PACKER_HOST}/VagrantCache /tmp/vagrant-cache || true
fi
