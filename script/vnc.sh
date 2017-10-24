#!/bin/bash -eux

if [[ ${PACKER_BUILDER_TYPE} =~ 'amazon' ]]; then
  echo "==> Configuring VNC for user interface"
  systemctl daemon-reload
  systemctl -q is-enabled gdm 2>/dev/null && systemctl disable gdm
  systemctl enable vncserver@:0.service
fi

