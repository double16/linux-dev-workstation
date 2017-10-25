#
# HashiCorp tools
#
class private::hashistack {
  archive { '/tmp/vagrant-cache/packer_1.1.1_linux_amd64.zip':
    ensure        => present,
    extract_path  => '/usr/bin',
    extract       => true,
    creates       => '/usr/bin/packer',
    source        => 'https://releases.hashicorp.com/packer/1.1.1/packer_1.1.1_linux_amd64.zip',
    checksum      => 'e407566e2063ac697e0bbf6f2dd334be448d58bed93f44a186408bf1fc54c552',
    checksum_type => 'sha256',
  }
  package { ['qemu', 'qemu-kvm']: }

  archive { '/tmp/vagrant-cache/vault_0.8.3_linux_amd64.zip':
    ensure        => present,
    extract_path  => '/usr/bin',
    extract       => true,
    creates       => '/usr/bin/vault',
    source        => 'https://releases.hashicorp.com/vault/0.8.3/vault_0.8.3_linux_amd64.zip',
    checksum      => 'a3b687904cd1151e7c7b1a3d016c93177b33f4f9ce5254e1d4f060fca2ac2626',
    checksum_type => 'sha256',
  }

  archive { '/tmp/vagrant-cache/consul_1.0.0_linux_amd64.zip':
    ensure        => present,
    extract_path  => '/usr/bin',
    extract       => true,
    creates       => '/usr/bin/consul',
    source        => 'https://releases.hashicorp.com/consul/1.0.0/consul_1.0.0_linux_amd64.zip',
    checksum      => '585782e1fb25a2096e1776e2da206866b1d9e1f10b71317e682e03125f22f479',
    checksum_type => 'sha256',
  }
}
