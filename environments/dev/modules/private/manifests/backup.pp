# Backup software and default config
class private::backup {
  package { 'backintime-qt': }
  ->file { '/home/vagrant/.config/backintime':
    ensure => directory,
    owner  => 'vagrant',
    group  => 'vagrant',
    mode   => '0755',
  }
  ->file { '/home/vagrant/.config/backintime/config':
    ensure  => file,
    replace => false,
    owner   => 'vagrant',
    group   => 'vagrant',
    source  => 'puppet:///modules/private/dotconfig/backintime-config',
    mode    => '0640',
  }

  package { [ 'duplicity', 'deja-dup' ]:
  }
}
