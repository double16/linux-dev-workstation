#
# Install Puppet Development Kit
#
class private::pdk {
  $pdk_config = lookup('pdk', Hash)
  $pdk_version = $pdk_config['version']
  $pdk_checksum = $pdk_config['checksum']

  archive { "/tmp/vagrant-cache/pdk-${pdk_version}-1.el7.x86_64.rpm":
    ensure          => present,
    source          => "https://pm.puppetlabs.com/cgi-bin/pdk_download.cgi?dist=el&rel=7&arch=x86_64&ver=${pdk_version}",
    extract         => true,
    extract_path    => '/tmp',
    extract_command => 'rpm -ivh %s',
    creates         => '/usr/local/bin/pdk',
    checksum        => $pdk_checksum,
    checksum_type   => 'sha256',
    require         => File['/tmp/vagrant-cache'],
  }
}
