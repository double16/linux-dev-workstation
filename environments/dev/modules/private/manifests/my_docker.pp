#
# Install Docker and related tools
#
class private::my_docker {

  $docker_base_version = lookup('docker', Hash)['version']
  $k8s_version = lookup('k8s', Hash)['version']

  unless $::virtual == 'docker' {
    require private::snap
    include private::snap_cache

    exec { 'microk8s':
      command => "/usr/bin/snap install microk8s --classic --channel=${k8s_version}/stable",
      creates => '/var/lib/snapd/snap/bin/microk8s.enable',
      timeout => 0,
      require => Exec['snap restore cache'],
      notify  => Exec['snap save cache'],
    }
    ->exec { 'microk8s available':
      command   => '/usr/bin/curl -sf http://127.0.0.1:8080/api?timeout=32s',
      timeout   => '300',
      tries     => 10,
      try_sleep => 10,
    }

    file { '/etc/tmpfiles.d/microk8s.conf':
      ensure  => file,
      content => 'L /var/run/docker.sock - - - - /var/snap/microk8s/current/docker.sock
',
      owner   => 0,
      group   => 'root',
      mode    => '0644',
    }

    file { '/var/local/microk8s':
      ensure => directory,
      owner  => 0,
      group  => 'root',
      mode   => '0755',
    }
    ['dns', 'dashboard', 'storage', 'ingress'].each |$addon| {
      exec { "microk8s addons ${addon}":
        command => "/var/lib/snapd/snap/bin/microk8s.enable ${addon} && touch /var/local/microk8s/${addon}",
        # microk8s doesn't appear to have a way to track enabled addons consistently
        creates => "/var/local/microk8s/${addon}",
        require => [ Exec['microk8s'], File['/var/local/microk8s'], Exec['microk8s available'] ],
      }
    }
    file { '/etc/profile.d/microk8s.sh':
      ensure  => file,
      owner   => 0,
      group   => 'root',
      mode    => '0644',
      content => '
alias docker=/var/lib/snapd/snap/bin/microk8s.docker
alias kubectl=/var/lib/snapd/snap/bin/microk8s.kubectl
alias istioctl=/var/lib/snapd/snap/bin/microk8s.istioctl
',
      require => Exec['microk8s'],
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

    file { '/etc/yum.repos.d/kubernetes.repo':
      ensure  => file,
      owner   => 0,
      group   => 'root',
      mode    => '0644',
      content => '[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
',
    }
    ->package { 'kubectl': }

    $minikube_config = lookup('minikube', Hash)
    $minikube_version = $minikube_config['version']
    $minikube_checksum = $minikube_config['checksum']
    private::cached_remote_file { '/usr/bin/minikube':
      cache_name    => "minikube-${minikube_version}",
      source        => "https://storage.googleapis.com/minikube/releases/v${minikube_version}/minikube-linux-amd64",
      # 2018-05-01 storage.googleapis.com uses a cross-signed TLS cert, current Ruby/Net::HTTP does not recognize it
      verify_peer   => false,
      owner         => 0,
      group         => 'root',
      mode          => '0755',
      checksum      => $minikube_checksum,
      checksum_type => 'sha256',
    }

    file_line { 'MINIKUBE_VM_DRIVER':
      path  => '/etc/environment',
      line  => 'MINIKUBE_VM_DRIVER=none',
      match => '^MINIKUBE_VM_DRIVER=',
    }

    file_line { 'CHANGE_MINIKUBE_NONE_USER':
      path  => '/etc/environment',
      line  => 'CHANGE_MINIKUBE_NONE_USER=true',
      match => '^CHANGE_MINIKUBE_NONE_USER=',
    }

    file_line { 'MINIKUBE_WANTNONEDRIVERWARNING':
      path  => '/etc/environment',
      line  => 'MINIKUBE_WANTNONEDRIVERWARNING=false',
      match => '^MINIKUBE_WANTNONEDRIVERWARNING=',
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
  private::cached_remote_file { '/usr/local/bin/container-diff':
    cache_name    => "container-diff-${condiff_version}",
    source        => "https://storage.googleapis.com/container-diff/v${condiff_version}/container-diff-linux-amd64",
    # 2018-05-01 storage.googleapis.com uses a cross-signed TLS cert, current Ruby/Net::HTTP does not recognize it
    verify_peer   => false,
    owner         => 0,
    group         => 'root',
    mode          => '0755',
    checksum      => $condiff_checksum,
    checksum_type => 'sha256',
  }

  $kustomize_config = lookup('kustomize', Hash)
  $kustomize_version = $kustomize_config['version']
  $kustomize_checksum = $kustomize_config['checksum']
  private::cached_remote_file { '/usr/local/bin/kustomize':
    cache_name    => "kustomize-${kustomize_version}",
    source        => "https://github.com/kubernetes-sigs/kustomize/releases/download/v${kustomize_version}/kustomize_${kustomize_version}_linux_amd64",
    # 2018-05-01 storage.googleapis.com uses a cross-signed TLS cert, current Ruby/Net::HTTP does not recognize it
    verify_peer   => false,
    owner         => 0,
    group         => 'root',
    mode          => '0755',
    checksum      => $kustomize_checksum,
    checksum_type => 'sha256',
  }

  file { '/etc/profile.d/kubectl-completion.sh':
    ensure  => file,
    owner   => 0,
    group   => 'root',
    mode    => '0755',
    content => 'command -v kubectl >/dev/null && source <(kubectl completion bash)',
  }

  $helm_config = lookup('helm', Hash)
  $helm_version = $helm_config['version']
  $helm_checksum = $helm_config['checksum']
  file { '/usr/local/share/helm':
    ensure => 'directory',
    mode   => '0755',
    owner  => 0,
    group  => 'root',
  }
  ->archive { "/tmp/vagrant-cache/helm-${helm_version}.tar.gz":
    ensure        => present,
    extract       => true,
    extract_path  => '/usr/local/share/helm',
    source        => "https://storage.googleapis.com/kubernetes-helm/helm-v${helm_version}-linux-amd64.tar.gz",
    checksum      => $helm_checksum,
    checksum_type => 'sha256',
    creates       => '/usr/local/share/helm/linux-amd64/helm',
    cleanup       => false,
    user          => 0,
    group         => 'root',
    require       => File['/tmp/vagrant-cache'],
  }
  ->file { '/usr/local/bin/helm':
    ensure => link,
    target => '/usr/local/share/helm/linux-amd64/helm',
    owner  => 0,
    group  => 'root',
  }
  ->file { '/usr/local/bin/tiller':
    ensure => link,
    target => '/usr/local/share/helm/linux-amd64/tiller',
    owner  => 0,
    group  => 'root',
  }
}
