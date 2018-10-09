#
# Installs the 'snap' package manager.
#
class private::snap_cache {
  exec { 'snap restore cache':
    command => '/usr/bin/rsync --archive --quiet /tmp/vagrant-cache/snap/ /var/lib/snapd/cache/',
    onlyif  => '/usr/bin/mountpoint /tmp/vagrant-cache && test -d /tmp/vagrant-cache/snap',
    require => [ Package['rsync'], Package['snapd'], File['/tmp/vagrant-cache'] ],
  }

  exec { 'snap save cache':
    command => '/usr/bin/mkdir -p /tmp/vagrant-cache/snap/ && /usr/bin/rsync --archive --quiet /var/lib/snapd/cache/ /tmp/vagrant-cache/snap/',
    onlyif  => '/usr/bin/mountpoint /tmp/vagrant-cache',
    require => [ Package['rsync'], Package['snapd'], File['/tmp/vagrant-cache'] ],
  }
}
