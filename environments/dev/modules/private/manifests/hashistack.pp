#
# HashiCorp tools
#
class private::hashistack {
  archive { '/tmp/vagrant-cache/packer_1.1.3_linux_amd64.zip':
    ensure        => present,
    extract_path  => '/usr/bin',
    extract       => true,
    creates       => '/usr/bin/packer',
    source        => 'https://releases.hashicorp.com/packer/1.1.3/packer_1.1.3_linux_amd64.zip',
    checksum      => 'b7982986992190ae50ab2feb310cb003a2ec9c5dcba19aa8b1ebb0d120e8686f',
    checksum_type => 'sha256',
    require       => File['/tmp/vagrant-cache'],
  }
  package { ['qemu', 'qemu-kvm']: }

  archive { '/tmp/vagrant-cache/vault_0.9.3_linux_amd64.zip':
    ensure        => present,
    extract_path  => '/usr/bin',
    extract       => true,
    creates       => '/usr/bin/vault',
    source        => 'https://releases.hashicorp.com/vault/0.9.3/vault_0.9.3_linux_amd64.zip',
    checksum      => '4ba8b9dafb903d20b4c87e8954015a07a6995f53a9650ac02b39e6cae502645e',
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
