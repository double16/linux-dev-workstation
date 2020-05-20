#!/bin/bash -eux

set +H

if [[ ${PACKER_BUILDER_TYPE} =~ 'docker' ]]; then
  echo "==> Configuring supervisord for Docker"
  if ! grep -q 'rpcinterface' "/etc/supervisord.conf"; then
          echo "==> Configuring supervisorctl"
          cat >> "/etc/supervisord.conf" <<EOF
[unix_http_server]
file=/run/supervisord.sock
[supervisorctl]
serverurl=unix:///run/supervisord.sock
[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface
EOF
  fi

  export ENABLE_SSHD_BOOTSTRAP=false ENABLE_SSHD_WRAPPER=false
  pkill -HUP supervisord || (/usr/bin/supervisord --configuration=/etc/supervisord.conf &)
fi
