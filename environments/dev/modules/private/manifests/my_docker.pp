class private::my_docker {
  unless $::virtual == 'docker' {

    $docker_version = $::operatingsystem ? {
      'Ubuntu' => "17.05.0~ce-0~ubuntu-${::lsbdistcodename}",
      'CentOS' => '17.05.0.ce-1.el7.centos',
      default => '17.05.0-ce',
    }
    class { '::docker':
      manage_package => true,
      package_name   => 'docker-engine',
      version        => $docker_version,
      docker_users   => [ 'vagrant' ],
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
