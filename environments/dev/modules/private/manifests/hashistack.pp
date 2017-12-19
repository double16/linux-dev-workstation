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

  archive { '/tmp/vagrant-cache/consul_1.0.2_linux_amd64.zip':
    ensure        => present,
    extract_path  => '/usr/bin',
    extract       => true,
    creates       => '/usr/bin/consul',
    source        => 'https://releases.hashicorp.com/consul/1.0.2/consul_1.0.2_linux_amd64.zip',
    checksum      => '418329f0f4fc3f18ef08674537b576e57df3f3026f258794b4b4b611beae6c9b',
    checksum_type => 'sha256',
    require       => File['/tmp/vagrant-cache'],
  }

  archive { '/tmp/vagrant-cache/terraform_0.11.1_linux_amd64.zip':
    ensure        => present,
    extract_path  => '/usr/bin',
    extract       => true,
    creates       => '/usr/bin/terraform',
    source        => 'https://releases.hashicorp.com/terraform/0.11.1/terraform_0.11.1_linux_amd64.zip',
    checksum      => '4e3d5e4c6a267e31e9f95d4c1b00f5a7be5a319698f0370825b459cb786e2f35',
    checksum_type => 'sha256',
    require       => File['/tmp/vagrant-cache'],
  }
}
