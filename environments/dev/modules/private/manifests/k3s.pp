# Install Kubernetes using https://k3s.io
class private::k3s {
  file { '/opt/k3s':
    ensure => directory,
    owner  => 'vagrant',
    group  => 'vagrant',
    mode   => '0755',
  }

  file { '/opt/k3s/until-ready.sh':
    ensure  => file,
    mode    => '0775',
    owner   => 'vagrant',
    group   => 'vagrant',
    content => '
#!/usr/bin/env bash
timeout 30 sh -c "until test -f /var/lib/rancher/k3s/server/node-token >/dev/null 2>&1; do echo .; sleep 1; done"
timeout 30 sh -c "until nc -zv localhost 6443 >/dev/null 2>&1; do echo .; sleep 1; done"
'
  }

  private::cached_remote_file { '/opt/k3s/install.sh':
    source  => 'https://get.k3s.io',
    mode    => '0755',
    require => File['/opt/k3s'],
  }
  ->private::cached_remote_file { '/opt/k3s/local-path-storage.yaml':
    source  => 'https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml',
    require => File['/opt/k3s'],
  }
  ->exec { '/opt/k3s/install.sh':
    environment => ['INSTALL_K3S_VERSION=v0.1.0', 'X_INSTALL_K3S_EXEC=server --docker'],
    creates     => '/etc/systemd/system/k3s.service',
  }
  ->exec { 'k3s local-path storage':
    command => '/opt/k3s/until-ready.sh && (/usr/local/bin/k3s kubectl apply -f /opt/k3s/local-path-storage.yaml ; /usr/local/bin/k3s kubectl patch storageclass local-path -p \'{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}\')',
    unless  => '/opt/k3s/until-ready.sh ; /usr/local/bin/k3s kubectl get storageclass local-path',
    require => File['/opt/k3s/until-ready.sh'],
  }

  file { '/home/vagrant/.kube':
    ensure => directory,
    mode   => '0775',
    owner  => 'vagrant',
    group  => 'vagrant',
  }
  file { '/home/vagrant/.kube/config':
    ensure => link,
    target => '/etc/rancher/k3s/k3s.yaml',
    owner  => 'vagrant',
    group  => 'vagrant',
  }
}
