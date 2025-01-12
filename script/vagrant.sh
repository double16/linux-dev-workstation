#!/bin/bash -eux

set +H

echo '==> Configuring settings for vagrant'

SSH_USER=${SSH_USERNAME:-vagrant}
SSH_USER_HOME=${SSH_USER_HOME:-/home/${SSH_USER}}
VAGRANT_INSECURE_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key"

# Packer passes boolean user variables through as '1', but this might change in
# the future, so also check for 'true'.
if [ "$INSTALL_VAGRANT_KEY" = "true" ] || [ "$INSTALL_VAGRANT_KEY" = "1" ]; then
  # Add vagrant user (if it doesn't already exist)
  if ! id -u $SSH_USER >/dev/null 2>&1; then
      echo "==> Creating ${SSH_USER}"
      /usr/sbin/groupadd $SSH_USER
      /usr/sbin/useradd $SSH_USER -g $SSH_USER
  fi
  chown -R "${SSH_USER}:${SSH_USER}" "${SSH_USER_HOME}"

  /usr/sbin/usermod -a -G wheel $SSH_USER

  if [ -n "$SUDO_USER" -a "$SSH_USER" != "$SUDO_USER" -a "$SUDO_USER" != "root" ]; then
    echo "==> Adding $SUDO_USER to group ${SSH_USER}"
    /usr/sbin/usermod -a -G $SSH_USER $SUDO_USER
  fi

  echo "==> Giving ${SSH_USER} sudo powers"
  echo "${SSH_USER}"|passwd --stdin $SSH_USER || true
  echo "${SSH_USER}        ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers

  echo "==> Installing Vagrant SSH key into ${SSH_USER_HOME}/.ssh/authorized_keys"
  mkdir -pm 700 ${SSH_USER_HOME}/.ssh
  # https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub
  echo "${VAGRANT_INSECURE_KEY}" > $SSH_USER_HOME/.ssh/authorized_keys
  chmod 0600 ${SSH_USER_HOME}/.ssh/authorized_keys
  chown -R ${SSH_USER}:${SSH_USER} ${SSH_USER_HOME}/.ssh
fi

