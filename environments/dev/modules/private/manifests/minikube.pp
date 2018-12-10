# Install Kubernetes `minikube` for single node use
class private::minikube {
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

  file_line { 'MINIKUBE_BOOTSTRAPPER':
    path  => '/etc/environment',
    line  => 'MINIKUBE_BOOTSTRAPPER=localkube',
    match => '^MINIKUBE_BOOTSTRAPPER=',
  }

  file_line { 'MINIKUBE_SHOWBOOTSTRAPPERDEPRECATIONNOTIFICATION':
    path  => '/etc/environment',
    line  => 'MINIKUBE_SHOWBOOTSTRAPPERDEPRECATIONNOTIFICATION=false',
    match => '^MINIKUBE_SHOWBOOTSTRAPPERDEPRECATIONNOTIFICATION=',
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
