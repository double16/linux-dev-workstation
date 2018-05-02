#
# Install vagrant and generally useful plugins
#
class private::my_vagrant {
  $version = lookup('vagrant', Hash)['version']

  class { 'vagrant':
    ensure  => present,
    version => $version,
  }
  vagrant::plugin { 'vagrant-vbguest':
    user => 'vagrant',
  }
  vagrant::plugin { 'vagrant-cachier':
    user => 'vagrant',
  }
}
