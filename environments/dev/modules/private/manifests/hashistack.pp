#
# HashiCorp tools
#
class private::hashistack {
  archive { '/tmp/vagrant-cache/packer_1.2.2_linux_amd64.zip':
    ensure        => present,
    extract_path  => '/usr/bin',
    extract       => true,
    creates       => '/usr/bin/packer',
    source        => 'https://releases.hashicorp.com/packer/1.2.2/packer_1.2.2_linux_amd64.zip',
    checksum      => '6575f8357a03ecad7997151234b1b9f09c7a5cf91c194b23a461ee279d68c6a8',
    checksum_type => 'sha256',
    require       => File['/tmp/vagrant-cache'],
  }
  package { ['qemu', 'qemu-kvm']: }

  archive { '/tmp/vagrant-cache/vault_0.10.0_linux_amd64.zip':
    ensure        => present,
    extract_path  => '/usr/bin',
    extract       => true,
    creates       => '/usr/bin/vault',
    source        => 'https://releases.hashicorp.com/vault/0.10.0/vault_0.10.0_linux_amd64.zip',
    checksum      => 'a6b4b6db132f3bbe6fbb77f76228ffa45bd55a5a1ab83ff043c2c665c3f5a744',
    checksum_type => 'sha256',
    require       => File['/tmp/vagrant-cache'],
  }

  archive { '/tmp/vagrant-cache/consul_1.0.7_linux_amd64.zip':
    ensure        => present,
    extract_path  => '/usr/bin',
    extract       => true,
    creates       => '/usr/bin/consul',
    source        => 'https://releases.hashicorp.com/consul/1.0.7/consul_1.0.7_linux_amd64.zip',
    checksum      => '6c2c8f6f5f91dcff845f1b2ce8a29bd230c11397c448ce85aae6dacd68aa4c14',
    checksum_type => 'sha256',
    require       => File['/tmp/vagrant-cache'],
  }

  archive { '/tmp/vagrant-cache/terraform_0.11.7_linux_amd64.zip':
    ensure        => present,
    extract_path  => '/usr/bin',
    extract       => true,
    creates       => '/usr/bin/terraform',
    source        => 'https://releases.hashicorp.com/terraform/0.11.7/terraform_0.11.7_linux_amd64.zip',
    checksum      => '6b8ce67647a59b2a3f70199c304abca0ddec0e49fd060944c26f666298e23418',
    checksum_type => 'sha256',
    require       => File['/tmp/vagrant-cache'],
  }
}
