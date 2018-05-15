#!/bin/bash -eux

if [[ ${PACKER_BUILDER_TYPE} =~ 'amazon' || ${PACKER_BUILDER_TYPE} =~ 'azure' || ${PACKER_BUILDER_TYPE} =~ 'docker' ]]; then
  echo "==> Configuring VNC for user interface"
  systemctl daemon-reload
  systemctl -q is-enabled gdm 2>/dev/null && systemctl disable gdm
  systemctl enable vncserver@:0.service
fi
