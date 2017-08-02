class my_sdkman {

  class { '::sdkman' : }
  ->file { '/home/vagrant/.sdkman':
    ensure => link,
    target => '/root/.sdkman',
  }
  ->file { '/tmp/vagrant-cache/sdkman':
    ensure => directory,
  }
  ->file { '/home/vagrant/.sdkman/archives':
    ensure => link,
    target => '/tmp/vagrant-cache/sdkman',
    force  => true,
  }
  ->file { '/etc/profile.d/sdkman.sh':
    ensure  => file,
    owner   => 0,
    group   => 'root',
    mode    => '0755',
    content => '[[ -s "/root/.sdkman/bin/sdkman-init.sh" ]] && source "/root/.sdkman/bin/sdkman-init.sh"',
  }

  exec { 'chmod 0755 /root/.sdkman':
    path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
    refreshonly => true,
    subscribe   => Class['sdkman'],
  } -> Sdkman::Package<| |>

  exec { 'chmod 0755 /root':
    path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
    refreshonly => true,
    subscribe   => Class['sdkman'],
  } -> Sdkman::Package<| |>

  sdkman::package { 'groovy':
    ensure     => present,
    version    => '2.4.12',
    is_default => true,
  }

  sdkman::package { 'groovyserv':
    ensure     => present,
    version    => '1.1.0',
    is_default => true,
  }

  sdkman::package { 'gradle':
    ensure     => present,
    version    => '4.0.2',
    is_default => true,
  }

  sdkman::package { 'grails':
    ensure     => present,
    version    => '3.2.10',
    is_default => true,
  }

}
