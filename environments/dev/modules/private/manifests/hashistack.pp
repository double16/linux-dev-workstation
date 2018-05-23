#
# HashiCorp tools
#
class private::hashistack {
  package { ['qemu', 'qemu-kvm']: }

  $config = lookup('hashistack', Hash)
  $config.each |$items| {
    $tool = $items[0]
    $version = $items[1]['version']
    $checksum = $items[1]['checksum']
    archive { "/tmp/vagrant-cache/${tool}_${version}_linux_amd64.zip":
      ensure        => present,
      extract_path  => '/usr/bin',
      extract       => true,
      cleanup       => false,
      creates       => "/usr/bin/${tool}",
      source        => "https://releases.hashicorp.com/${tool}/${version}/${tool}_${version}_linux_amd64.zip",
      checksum      => $checksum,
      checksum_type => 'sha256',
      require       => File['/tmp/vagrant-cache'],
    }
  }
}
