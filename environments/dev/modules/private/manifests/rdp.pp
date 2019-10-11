#
# Configure RDP server for vagrant user to run on start on localhost port 3389
#
class private::rdp {
  package { 'xorgxrdp':}
  ->package { 'xrdp': }
  ->ini_setting { 'xrdp default to Xorg':
    path    => '/etc/xrdp/xrdp.ini',
    section => 'Globals',
    setting => 'autorun',
    value   => 'Xorg',
  }
  ->file_line { 'sesman fix Xorg path':
    path               => '/etc/xrdp/sesman.ini',
    line               => 'param=/usr/libexec/Xorg',
    match              => '^param=Xorg$',
    append_on_no_match => false,
    multiple           => false,
  }
  ->ini_setting { 'sesman disable root login':
    path    => '/etc/xrdp/sesman.ini',
    section => 'Security',
    setting => 'AllowRootLogin',
    value   => 'false',
  }
  ->ini_setting { 'sesman rdp_drives':
    path    => '/etc/xrdp/sesman.ini',
    section => 'Chansrv',
    setting => 'FuseMountName',
    value   => 'rdp_drives',
  }
  ->file { '/etc/X11/Xwrapper.config':
    ensure => present,
    owner  => 0,
    group  => 'root',
    mode   => '0644',
  }
  ->file_line { 'allow anybody to start Xorg':
    path  => '/etc/X11/Xwrapper.config',
    line  => 'allowed_users = anybody',
    match => '^allowed_users[ ]*=',
  }
  ->service { ['xrdp', 'xrdp-sesman']:
    enable => true,
  }

  [
    [ 'name', 'Xorg' ],
    [ 'lib', 'libxup.so' ],
    [ 'username', 'vagrant' ],
    [ 'password', 'ask' ],
    [ 'ip', '127.0.0.1' ],
    [ 'port', '-1' ],
    [ 'code', '20' ],
    [ 'channel.rdpdr', 'true' ],
    [ 'channel.rdpsnd', 'true' ],
    [ 'channel.drdynvc', 'true' ],
    [ 'channel.cliprdr', 'true' ],
    [ 'channel.rail', 'true' ],
    [ 'channel.xrdpvr', 'true' ],
  ].each |$kv| {
    ini_setting { "Xorg session config ${kv[0]}":
      path    => '/etc/xrdp/xrdp.ini',
      section => 'Xorg',
      setting => $kv[0],
      value   => $kv[1],
      require => [ Package['xrdp'], Package['xorgxrdp'] ],
      before  => [ Service['xrdp'], Service['xrdp-sesman'] ],
    }
  }

  [
    [ 'name', 'Xvnc' ],
    [ 'lib', 'libvnc.so' ],
    [ 'username', 'vagrant' ],
    [ 'password', 'ask' ],
    [ 'ip', '127.0.0.1' ],
    [ 'port', '-1' ],
    [ 'channel.rdpdr', 'true' ],
    [ 'channel.rdpsnd', 'true' ],
    [ 'channel.drdynvc', 'true' ],
    [ 'channel.cliprdr', 'true' ],
    [ 'channel.rail', 'true' ],
    [ 'channel.xrdpvr', 'true' ],
  ].each |$kv| {
    ini_setting { "Xvnc session config ${kv[0]}":
      path    => '/etc/xrdp/xrdp.ini',
      section => 'Xvnc',
      setting => $kv[0],
      value   => $kv[1],
      require => [ Package['xrdp'], Package['xorgxrdp'] ],
      before  => [ Service['xrdp'], Service['xrdp-sesman'] ],
    }
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

  if $::virtual == 'docker' {
    file { '/etc/supervisord.d/xrdp.conf': 
      ensure => file,
      owner  => 0,
      group  => 'root',
      mode   => '0644',
      source => 'puppet:///modules/private/supervisord-xrdp.conf',
    }
    file { '/etc/supervisord.d/xrdp-sesman.conf': 
      ensure => file,
      owner  => 0,
      group  => 'root',
      mode   => '0644',
      source => 'puppet:///modules/private/supervisord-sesman.conf',
    }
  }
}
