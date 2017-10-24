#
# HashiCorp tools
#
class private::hashistack {
  archive { 'packer_1.1.1_linux_amd64':
    ensure           => present,
    target           => '/usr/bin',
    url              => 'https://releases.hashicorp.com/packer/1.1.1/packer_1.1.1_linux_amd64.zip',
    extension        => 'zip',
    follow_redirects => true,
    digest_string    => 'e407566e2063ac697e0bbf6f2dd334be448d58bed93f44a186408bf1fc54c552',
    digest_type      => 'sha256',
  }
  package { ['qemu', 'qemu-kvm']: }

  archive { 'vault_0.8.3_linux_amd64':
    ensure           => present,
    target           => '/usr/bin',
    url              => 'https://releases.hashicorp.com/vault/0.8.3/vault_0.8.3_linux_amd64.zip',
    extension        => 'zip',
    follow_redirects => true,
    digest_string    => 'a3b687904cd1151e7c7b1a3d016c93177b33f4f9ce5254e1d4f060fca2ac2626',
    digest_type      => 'sha256',
  }

  archive { 'consul_1.0.0_linux_amd64':
    ensure           => present,
    target           => '/usr/bin',
    url              => 'https://releases.hashicorp.com/consul/1.0.0/consul_1.0.0_linux_amd64.zip',
    extension        => 'zip',
    follow_redirects => true,
    digest_string    => '585782e1fb25a2096e1776e2da206866b1d9e1f10b71317e682e03125f22f479',
    digest_type      => 'sha256',
  }
}