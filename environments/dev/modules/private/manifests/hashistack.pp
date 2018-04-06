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

  archive { '/tmp/vagrant-cache/terraform_0.11.4_linux_amd64.zip':
    ensure        => present,
    extract_path  => '/usr/bin',
    extract       => true,
    creates       => '/usr/bin/terraform',
    source        => 'https://releases.hashicorp.com/terraform/0.11.4/terraform_0.11.4_linux_amd64.zip',
    checksum      => '817be651ca41b999c09250a9fcade541a941afab41c0c663bd25529a4d5cfd31',
    checksum_type => 'sha256',
    require       => File['/tmp/vagrant-cache'],
  }
}
