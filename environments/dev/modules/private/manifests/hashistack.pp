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

  archive { '/tmp/vagrant-cache/vault_0.9.1_linux_amd64.zip':
    ensure        => present,
    extract_path  => '/usr/bin',
    extract       => true,
    creates       => '/usr/bin/vault',
    source        => 'https://releases.hashicorp.com/vault/0.9.1/vault_0.9.1_linux_amd64.zip',
    checksum      => '6308013ee0d6278e98cdfe8d6de0162102a8d25f3bcd1e3737bf7b022a9f6702',
    checksum_type => 'sha256',
    require       => File['/tmp/vagrant-cache'],
  }

  archive { '/tmp/vagrant-cache/consul_1.0.3_linux_amd64.zip':
    ensure        => present,
    extract_path  => '/usr/bin',
    extract       => true,
    creates       => '/usr/bin/consul',
    source        => 'https://releases.hashicorp.com/consul/1.0.3/consul_1.0.3_linux_amd64.zip',
    checksum      => '4782e4662de8effe49e97c50b1a1233c03c0026881f6c004144cc3b73f446ec5',
    checksum_type => 'sha256',
    require       => File['/tmp/vagrant-cache'],
  }

  archive { '/tmp/vagrant-cache/terraform_0.11.2_linux_amd64.zip':
    ensure        => present,
    extract_path  => '/usr/bin',
    extract       => true,
    creates       => '/usr/bin/terraform',
    source        => 'https://releases.hashicorp.com/terraform/0.11.2/terraform_0.11.2_linux_amd64.zip',
    checksum      => 'f728fa73ff2a4c4235a28de4019802531758c7c090b6ca4c024d48063ab8537b',
    checksum_type => 'sha256',
    require       => File['/tmp/vagrant-cache'],
  }
}
