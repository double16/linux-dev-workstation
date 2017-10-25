#
# Security config that needs to be before everything else
#
class private::security {
  file { '/usr/local/sbin/import-certs.sh':
    ensure => file,
    owner  => 0,
    group  => 'root',
    mode   => '0755',
    source => 'puppet:///modules/private/import-certs.sh',
  }
  ->exec { '/usr/local/sbin/import-certs.sh': }

  file { '/usr/local/sbin/import-ssh-keys.sh':
    ensure => file,
    owner  => 0,
    group  => 'root',
    mode   => '0755',
    source => 'puppet:///modules/private/import-ssh-keys.sh',
  }
  ->exec { '/usr/local/sbin/import-ssh-keys.sh': }
}

