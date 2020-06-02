#!/bin/bash -eux

set +H -eu

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

  echo "==> Reloading supervisord"
  if ! pkill -HUP supervisord; then
    echo "==> Starting supervisord"
    export ENABLE_SSHD_BOOTSTRAP=false ENABLE_SSHD_WRAPPER=false ENABLE_SUPERVISOR_STDOUT=false
    nohup /usr/bin/supervisord --configuration=/etc/supervisord.conf &>/dev/null &
  fi
fi
