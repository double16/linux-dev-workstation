class private::my_sdkman {

  class { '::sdkman' :
    owner   => 'vagrant',
    group   => 'vagrant',
    require => [ Package['which'], Package['unzip'] ],
  }
  ->file { '/tmp/vagrant-cache/sdkman':
    ensure => directory,
    owner  => 'vagrant',
    group  => 'vagrant',
  }
  ->file { '/home/vagrant/.sdkman/archives':
    ensure => link,
    owner  => 'vagrant',
    group  => 'vagrant',
    target => '/tmp/vagrant-cache/sdkman',
    force  => true,
  }
  ->file { '/etc/profile.d/sdkman.sh':
    ensure  => file,
    owner   => 0,
    group   => 'root',
    mode    => '0755',
    content => '[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"',
  }

  File['/home/vagrant/.sdkman/archives']
  -> Sdkman::Package<| |>

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
    version    => '4.3.1',
    is_default => true,
  }

  sdkman::package { 'grails':
    ensure     => present,
    version    => '3.2.11',
    is_default => true,
  }

  # Something isn't working with the is_default parameter, so we use a dependency to get java8 to install last
  sdkman::package { 'java9':
    ensure       => present,
    package_name => 'java',
    version      => '9.0.0-zulu',
    is_default   => false,
  }
  ->sdkman::package { 'java8':
    ensure       => present,
    package_name => 'java',
    version      => '8u152-zulu',
    is_default   => true,
  }

}

