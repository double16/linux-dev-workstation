#!/bin/bash -eux

set +H

if [[ ${PACKER_BUILDER_TYPE} =~ 'amazon' || ${PACKER_BUILDER_TYPE} =~ 'azure' || ${PACKER_BUILDER_TYPE} =~ 'hyperv' ]]; then
  echo "==> Configuring RDP for primary user interface"
  systemctl daemon-reload
  systemctl set-default multi-user.target
  systemctl enable xrdp.service
  systemctl enable xrdp-sesman.service
fi
