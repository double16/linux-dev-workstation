#!/bin/bash -eux

if [[ ${PACKER_BUILDER_TYPE} =~ 'docker' ]]; then
  echo "==> Configuring Docker-in-Docker"
  cat >/etc/supervisord.d/dind.conf <<EOF
[program:dockerd]
priority = 15
command = /bin/sh -c "if [ -S /var/run/docker.sock ] && /usr/bin/docker version >/dev/null 2>&1; then chgrp docker /var/run/docker.sock; else /usr/bin/dockerd --host=unix:///var/run/docker.sock --host=tcp://0.0.0.0:2375 --storage-driver vfs; fi"
autostart = true
startsecs = 10
startretries = 3
autorestart = true
redirect_stderr = true
stdout_logfile = /var/log/docker.log
stdout_events_enabled = true
EOF

  cat >/etc/supervisord.d/k3s.conf <<EOF
[program:k3s]
priority = 16
command = /opt/k3s/start-k3s.sh
autostart = true
startsecs = 10
startretries = 3
autorestart = false
redirect_stderr = true
stdout_logfile = /var/log/k3s.log
stdout_events_enabled = true
EOF

fi
