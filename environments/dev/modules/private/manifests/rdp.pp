#
# Configure RDP server for vagrant user to run on start on localhost port 3389
#
class private::rdp {
  if $::os['release']['full'] == '7.6.1810' {
    # EPEL upgraded xorgxrdp using deps not available in CentOS 7.6
    exec { "/usr/bin/yum makecache -y ; /usr/bin/rpm -Uvh --nodeps $(/usr/bin/repoquery --quiet --location xorgxrdp | grep '^http.*xorgxrdp.*rpm$')":
      unless => '/usr/bin/yum list installed xorgxrdp',
      before => Package['xrdp'],
    }
  } else {
    package { 'xorgxrdp':
      before => Package['xrdp'],
    }
  }

  package { 'xrdp': }
  ->file { '/etc/xrdp/xrdp.ini':
    ensure => file,
    source => 'puppet:///modules/private/xrdp.ini',
    backup => true,
    owner  => 0,
    group  => 'root',
    mode   => '0644',
    notify => Service['xrdp'],
  }
  ->file { '/etc/xrdp/sesman.ini':
    ensure => file,
    source => 'puppet:///modules/private/sesman.ini',
    backup => true,
    owner  => 0,
    group  => 'root',
    mode   => '0644',
    notify => Service['xrdp-sesman'],
  }
  ->service { ['xrdp', 'xrdp-sesman']:
    enable => true,
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
After=xrdp.service

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

  file { '/home/vagrant/.Xclients':
    ensure  => file,
    owner   => 'vagrant',
    group   => 'vagrant',
    mode    => '0775',
    content => '#!/bin/sh
exec xfce4-session
',
  }
}
