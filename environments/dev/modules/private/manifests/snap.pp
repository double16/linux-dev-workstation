#
# Installs the 'snap' package manager.
#
class private::snap {
  yum::plugin { 'copr':
    ensure => present,
  }
  ->exec { '/usr/bin/yum copr enable -y ngompa/snapcore-el7':
    creates => '/etc/yum.repos.d/_copr_ngompa-snapcore-el7.repo',
  }
  ->package { 'snapd':
    ensure => present,
  }
  ->file { '/snap':
    ensure => link,
    target => '/var/lib/snapd/snap',
    owner  => 0,
    group  => 'root',
  }
  ->exec { '/usr/bin/systemctl enable --now snapd.socket':
    creates => '/etc/systemd/system/sockets.target.wants/snapd.socket',
  }
}
