#
# HashiCorp tools
#
class private::hashistack {
  archive { '/tmp/vagrant-cache/packer_1.2.1_linux_amd64.zip':
    ensure        => present,
    extract_path  => '/usr/bin',
    extract       => true,
    creates       => '/usr/bin/packer',
    source        => 'https://releases.hashicorp.com/packer/1.2.1/packer_1.2.1_linux_amd64.zip',
    checksum      => 'dd90f00b69c4d8f88a8d657fff0bb909c77ebb998afd1f77da110bc05e2ed9c3',
    checksum_type => 'sha256',
    require       => File['/tmp/vagrant-cache'],
  }
  package { ['qemu', 'qemu-kvm']: }

  archive { '/tmp/vagrant-cache/vault_0.9.5_linux_amd64.zip':
    ensure        => present,
    extract_path  => '/usr/bin',
    extract       => true,
    creates       => '/usr/bin/vault',
    source        => 'https://releases.hashicorp.com/vault/0.9.5/vault_0.9.5_linux_amd64.zip',
    checksum      => 'f6dbc9fdac00598d2a319c9b744b85bf17d9530298f93d29ef2065bc751df099',
    checksum_type => 'sha256',
    require       => File['/tmp/vagrant-cache'],
  }

  archive { '/tmp/vagrant-cache/consul_1.0.6_linux_amd64.zip':
    ensure        => present,
    extract_path  => '/usr/bin',
    extract       => true,
    creates       => '/usr/bin/consul',
    source        => 'https://releases.hashicorp.com/consul/1.0.6/consul_1.0.6_linux_amd64.zip',
    checksum      => 'bcc504f658cef2944d1cd703eda90045e084a15752d23c038400cf98c716ea01',
    checksum_type => 'sha256',
    require       => File['/tmp/vagrant-cache'],
  }

  archive { '/tmp/vagrant-cache/terraform_0.11.3_linux_amd64.zip':
    ensure        => present,
    extract_path  => '/usr/bin',
    extract       => true,
    creates       => '/usr/bin/terraform',
    source        => 'https://releases.hashicorp.com/terraform/0.11.3/terraform_0.11.3_linux_amd64.zip',
    checksum      => '6b8a7b83954597d36bbed23913dd51bc253906c612a070a21db373eab71b277b',
    checksum_type => 'sha256',
    require       => File['/tmp/vagrant-cache'],
  }
}
