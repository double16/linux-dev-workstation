#
# HashiCorp tools
#
class private::hashistack {
  archive { '/tmp/vagrant-cache/packer_1.1.2_linux_amd64.zip':
    ensure        => present,
    extract_path  => '/usr/bin',
    extract       => true,
    creates       => '/usr/bin/packer',
    source        => 'https://releases.hashicorp.com/packer/1.1.2/packer_1.1.2_linux_amd64.zip',
    checksum      => '7e315a6110333d9d4269ac2ec5c68e663d82a4575d3e853996a976875612724b',
    checksum_type => 'sha256',
    require       => File['/tmp/vagrant-cache'],
  }
  package { ['qemu', 'qemu-kvm']: }

  archive { '/tmp/vagrant-cache/vault_0.9.0_linux_amd64.zip':
    ensure        => present,
    extract_path  => '/usr/bin',
    extract       => true,
    creates       => '/usr/bin/vault',
    source        => 'https://releases.hashicorp.com/vault/0.9.0/vault_0.9.0_linux_amd64.zip',
    checksum      => '801ce0ceaab4d2e59dbb35ea5191cfe8e6f36bb91500e86bec2d154172de59a4',
    checksum_type => 'sha256',
    require       => File['/tmp/vagrant-cache'],
  }

  archive { '/tmp/vagrant-cache/consul_1.0.0_linux_amd64.zip':
    ensure        => present,
    extract_path  => '/usr/bin',
    extract       => true,
    creates       => '/usr/bin/consul',
    source        => 'https://releases.hashicorp.com/consul/1.0.0/consul_1.0.0_linux_amd64.zip',
    checksum      => '585782e1fb25a2096e1776e2da206866b1d9e1f10b71317e682e03125f22f479',
    checksum_type => 'sha256',
    require       => File['/tmp/vagrant-cache'],
  }
}
