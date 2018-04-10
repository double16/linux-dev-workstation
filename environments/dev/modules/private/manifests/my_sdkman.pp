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
    version    => '2.4.15',
    is_default => true,
  }

  sdkman::package { 'groovyserv':
    ensure     => present,
    version    => '1.2.0',
    is_default => true,
  }

  sdkman::package { 'gradle':
    ensure     => present,
    version    => '4.6',
    is_default => true,
  }

  sdkman::package { 'grails 3.2':
    ensure       => present,
    package_name => 'grails',
    version      => '3.2.12',
    is_default   => false,
  }

  sdkman::package { 'grails 3.3':
    ensure       => present,
    package_name => 'grails',
    version      => '3.3.2',
    is_default   => true,
  }

  # Something isn't working with the is_default parameter, so we use a dependency to get java8 to install last
  sdkman::package { 'java9':
    ensure       => present,
    package_name => 'java',
    version      => '9.0.4-openjdk',
    is_default   => false,
  }
  ->sdkman::package { 'java8':
    ensure       => present,
    package_name => 'java',
    version      => '8.0.163-zulu',
    is_default   => true,
  }
  ->sdkman::package { 'java10':
    ensure       => present,
    package_name => 'java',
    version      => '10.0.0-openjdk',
    is_default   => false,
  }

}

