#
# Install Puppet Development Kit
#
class private::pdk {
  package { 'puppet-tools-release':
    provider => 'rpm',
    source   => 'https://yum.puppet.com/puppet-tools-release-fedora-31.noarch.rpm',
  }
  ->package { 'pdk': }
}
