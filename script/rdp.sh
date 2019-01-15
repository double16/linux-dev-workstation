#!/bin/bash -eux

if [[ ${PACKER_BUILDER_TYPE} =~ 'amazon' || ${PACKER_BUILDER_TYPE} =~ 'azure' || ${PACKER_BUILDER_TYPE} =~ 'docker' || ${PACKER_BUILDER_TYPE} =~ 'hyperv' ]]; then
  echo "==> Configuring RDP for primary user interface"
  systemctl daemon-reload
  systemctl -q is-enabled gdm 2>/dev/null && systemctl disable gdm
  systemctl enable xrdp.service
  systemctl enable xrdp-sesman.service
fi

if [[ ${PACKER_BUILDER_TYPE} =~ 'docker' ]]; then
  echo "==> Configuring RDP for supervisord"
  cat >/etc/supervisord.d/xrdp.conf <<EOF
[program:xrdp]
priority = 15
command = /usr/sbin/xrdp --nodaemon
autostart = true
startsecs = 0
startretries = 0
autorestart = true
redirect_stderr = true
stdout_logfile = /var/log/xrdp
stdout_events_enabled = true
EOF

  cat >/etc/supervisord.d/xrdp-sesman.conf <<EOF
[program:xrdp-sesman]
priority = 16
command = /usr/sbin/xrdp-sesman --nodaemon
autostart = true
startsecs = 0
startretries = 0
autorestart = true
redirect_stderr = true
stdout_logfile = /var/log/xrdp-sesman
stdout_events_enabled = true
EOF

fi
