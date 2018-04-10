#
# Install Docker and related tools
#
class private::my_docker {
  unless $::virtual == 'docker' {

    $docker_version = $::operatingsystem ? {
      'Ubuntu' => '18.03.0~ce-0~ubuntu',
      'CentOS' => '18.03.0.ce-1.el7.centos',
      default  => '18.03.0-ce',
    }

    package { 'docker-engine': ensure => absent, }
    ->file { '/etc/sysctl.d/forwarding.conf':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => '# IP forwarding for Docker
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
',
    }
    ->remote_file { '/etc/yum.repos.d/docker-ce.repo':
      source => 'https://download.docker.com/linux/centos/docker-ce.repo',
    }
    ->package { ['device-mapper-persistent-data', 'lvm2']: }
    ->package { 'docker-ce':
      ensure => $docker_version,
    }
    ->class { '::docker':
      manage_package              => false,
      use_upstream_package_source => false,
      docker_users                => [ 'vagrant' ],
      service_overrides_template  => 'private/docker-service-overrides.erb',
    }

    cron { 'docker-prune':
      ensure  => present,
      user    => 'root',
      command => 'docker system prune -f',
      special => 'weekly',
    }
  }

  package { 'docker-compose':
    ensure   => present,
    provider => 'pip',
  }

  file { '/usr/local/bin/docker-clean':
    ensure => absent,
  }

  remote_file { '/usr/local/bin/container-diff':
    source        => 'https://storage.googleapis.com/container-diff/v0.5.2/container-diff-linux-amd64',
    owner         => 0,
    group         => 'root',
    mode          => '0755',
    checksum      => '49a4050e1fc4015bdb9f9be3aa6acf846ac45fe9a1b782568f1bd66b9d3dd917',
    checksum_type => 'sha256',
  }
}
