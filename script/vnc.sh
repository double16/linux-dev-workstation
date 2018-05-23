#!/bin/bash -eux

if [[ ${PACKER_BUILDER_TYPE} =~ 'amazon' || ${PACKER_BUILDER_TYPE} =~ 'azure' || ${PACKER_BUILDER_TYPE} =~ 'docker' ]]; then
  echo "==> Configuring VNC for user interface"
  systemctl daemon-reload
  systemctl -q is-enabled gdm 2>/dev/null && systemctl disable gdm
  systemctl enable vncserver@:0.service
fi

if [[ ${PACKER_BUILDER_TYPE} =~ 'docker' ]]; then
  echo "==> Configuring VNC for supervisord"
  cat >/etc/supervisord.d/vncserver.conf <<EOF
[program:vncserver]
priority = 15
command = /usr/sbin/runuser -l ${SSH_USERNAME:-vagrant} -c "/usr/bin/vncserver :0"
autostart = true
startsecs = 0
startretries = 0
autorestart = false
redirect_stderr = true
stdout_logfile = /var/log/vncserver0
stdout_events_enabled = true
EOF

fi

