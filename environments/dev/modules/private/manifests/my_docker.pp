#
# Install Docker and related tools
#
class private::my_docker {

  $docker_base_version = lookup('docker', Hash)['version']
  $docker_version = $::operatingsystem ? {
    'Ubuntu' => "${docker_base_version}~ce-0~ubuntu",
    'CentOS' => "${docker_base_version}.ce-1.el7.centos",
    default  => "${docker_base_version}-ce",
  }

  unless $::virtual == 'docker' {
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
  } else {
    # Docker in Docker (dind), based on https://github.com/aws/aws-codebuild-docker-images/blob/master/ubuntu/docker/17.09.0/Dockerfile
    package { [ 'e2fsprogs', 'iptables', 'xfsprogs', 'kmod']: }
    archive { "/tmp/vagrant-cache/docker-${docker_base_version}-ce.tgz":
      ensure        => present,
      extract       => true,
      extract_path  => '/usr/bin',
      source        => "https://download.docker.com/linux/static/stable/x86_64/docker-${docker_base_version}-ce.tgz",
      creates       => '/usr/bin/docker',
      cleanup       => false,
      extract_flags => '-x --strip-components 1 -f',
    }
    remote_file { '/usr/bin/dind':
      ensure => present,
      source => 'https://raw.githubusercontent.com/moby/moby/52379fa76dee07ca038624d639d9e14f4fb719ff/hack/dind',
      mode   => '0755',
    }
    group { 'docker': }
    user { 'docker':
      gid        => 'docker',
      managehome => false,
      system     => true,
    }
    group { 'dockerremap': }
    user { 'dockerremap':
      gid        => 'dockerremap',
      managehome => false,
      system     => true,
    }
    file { '/etc/subuid':
      ensure  => file,
      content => 'dockremap:165536:65536',
    }
    file { '/etc/subgid':
      ensure  => file,
      content => 'dockremap:165536:65536',
    }
  }

  package { 'docker-compose':
    ensure   => present,
    provider => 'pip',
  }

  file { '/usr/local/bin/docker-clean':
    ensure => absent,
  }

  $condiff_config = lookup('container-diff', Hash)
  $condiff_version = $condiff_config['version']
  $condiff_checksum = $condiff_config['checksum']
  remote_file { '/usr/local/bin/container-diff':
    source        => "https://storage.googleapis.com/container-diff/v${condiff_version}/container-diff-linux-amd64",
    # 2018-05-01 storage.googleapis.com uses a cross-signed TLS cert, current Ruby/Net::HTTP does not recognize it
    verify_peer   => false,
    owner         => 0,
    group         => 'root',
    mode          => '0755',
    checksum      => $condiff_checksum,
    checksum_type => 'sha256',
  }
}
