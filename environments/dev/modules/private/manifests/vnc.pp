#
# Configure VNC server for vagrant user to run on start on localhost port 5900
#
class private::vnc {
  package { ['tigervnc-server', 'x11vnc']: }
  ->exec { 'Configure vagrant user in VNC service':
    path    => [ '/bin', '/sbin', '/usr/bin', '/usr/sbin' ],
    command => "sed -i 's/<USER>/vagrant/g' /usr/lib/systemd/system/vncserver@.service",
    onlyif  => "grep -qF '<USER>' /usr/lib/systemd/system/vncserver@.service",
  }

  file { '/usr/sbin/aws-vagrant-auth.sh':
    ensure  => file,
    owner   => 0,
    group   => 'root',
    mode    => '0755',
    content => '#!/bin/sh
if [[ -f ~centos/.ssh/authorized_keys ]]; then
  cat ~vagrant/.ssh/authorized_keys ~centos/.ssh/authorized_keys | sort | uniq >> ~vagrant/.ssh/authorized_keys.next
  chown vagrant:vagrant ~vagrant/.ssh/authorized_keys.next
  chmod 0600 ~vagrant/.ssh/authorized_keys.next
  mv ~vagrant/.ssh/authorized_keys.next ~vagrant/.ssh/authorized_keys
fi
',
  }

  file { '/usr/lib/systemd/system/aws-vagrant-auth.service':
    ensure  => file,
    owner   => 0,
    group   => 'root',
    mode    => '0644',
    content => '[Unit]
Description=Copy AWS SSH key authorizations to vagrant
After=vncserver@:0.service

[Service]
Type=oneshot
ExecStart=/usr/sbin/aws-vagrant-auth.sh

[Install]
WantedBy=multi-user.target
',
  }
  ->service { 'aws-vagrant-auth':
    enable => true,
  }

  file { '/home/vagrant/.vnc':
    ensure => directory,
    owner  => 'vagrant',
    group  => 'vagrant',
    mode   => '0755',
  }
  file { '/home/vagrant/.vnc/config':
    ensure  => file,
    owner   => 'vagrant',
    group   => 'vagrant',
    mode    => '0644',
    content => '
## Supported server options to pass to vncserver upon invocation can be listed
## in this file. See the following manpages for more: vncserver(1) Xvnc(1).
securitytypes=none
desktop=developer-workstation
localhost
alwaysshared
',
  }
  file { '/home/vagrant/.vnc/xstartup':
    ensure  => file,
    owner   => 'vagrant',
    group   => 'vagrant',
    mode    => '0755',
    content => '#!/bin/sh

unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
startxfce4 &

[ -x /etc/vnc/xstartup ] && exec /etc/vnc/xstartup
[ -r $HOME/.Xresources ] && xrdb $HOME/.Xresources
xsetroot -solid grey
vncconfig -iconic &
',
  }
}
