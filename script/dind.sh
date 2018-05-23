#!/bin/bash -eux

if [[ ${PACKER_BUILDER_TYPE} =~ 'docker' ]]; then
  echo "==> Configuring Docker-in-Docker"
  cat >/etc/supervisord.d/dind.conf <<EOF
[program:dockerd]
priority = 15
command = /bin/sh -c "if [ -S /var/run/docker.sock ]; then chown vagrant:docker /var/run/docker.sock; else /usr/bin/dockerd --host=unix:///var/run/docker.sock --host=tcp://0.0.0.0:2375; fi"
autostart = true
startsecs = 0
startretries = 0
autorestart = false
redirect_stderr = true
stdout_logfile = /var/log/docker
stdout_events_enabled = true
EOF

fi

