class private::my_docker {
  unless $::virtual == 'docker' {

    $docker_version = $::operatingsystem ? {
      'Ubuntu' => "17.09.0~ce-0~ubuntu-${::lsbdistcodename}",
      'CentOS' => '17.09.0.ce-1.el7.centos',
      default => '17.09.0-ce',
    }

    package { 'docker-engine': ensure => absent, }
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
}
