#
# Install Puppet Development Kit
#
class private::pdk {
  $pdk_version = '1.3.2.0'

  archive { "/tmp/vagrant-cache/pdk-${pdk_version}-1.el7.x86_64.rpm":
    ensure          => present,
    source          => "https://pm.puppetlabs.com/cgi-bin/pdk_download.cgi?dist=el&rel=7&arch=x86_64&ver=${pdk_version}",
    extract         => true,
    extract_path    => '/tmp',
    extract_command => 'rpm -ivh %s',
    creates         => '/usr/local/bin/pdk',
    checksum        => '96540af3ab726a09485aefc2213415c92ffeef34b58de1211926e5429b9a2258',
    checksum_type   => 'sha256',
    require         => File['/tmp/vagrant-cache'],
  }
}
