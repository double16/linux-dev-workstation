#
# Install Puppet Development Kit
#
class private::pdk {
  $pdk_version = '1.2.1.0'

  remote_file { "/tmp/vagrant-cache/pdk-${pdk_version}-1.el7.x86_64.rpm":
    ensure        => present,
    source        => "https://pm.puppetlabs.com/cgi-bin/pdk_download.cgi?dist=el&rel=7&arch=x86_64&ver=${pdk_version}",
    checksum      => '11fdde6448e30844b2afe8f350c15ada94fb1ddf6199a5a0f4aecc6b149d3410',
    checksum_type => 'sha256',
    require       => File['/tmp/vagrant-cache'],
  }
  ->package { 'pdk':
    source   => "/tmp/vagrant-cache/pdk-${pdk_version}-1.el7.x86_64.rpm",
    provider => 'rpm',
  }
}
