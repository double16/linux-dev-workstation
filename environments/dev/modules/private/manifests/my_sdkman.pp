#
# Uses SDKMan to install several Java based tools, including the JDK itself.
#
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

  # Something isn't working with the is_default parameter, so we use dependencies because the last installed will be the default
  Sdkman::Package<| is_default == false |>
  ->Sdkman::Package<| is_default == true |>

  $packages = lookup('sdkman', Array)
  $packages.each |$item| {
    $package = $item['package']
    $version = $item['version']
    $is_default = pick($item['default'], false)
    sdkman::package { "${package} ${version}":
      ensure       => present,
      package_name => $package,
      version      => $version,
      is_default   => $is_default,
    }
  }
}
