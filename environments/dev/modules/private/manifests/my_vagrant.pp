#
# Install vagrant and generally useful plugins
#
class private::my_vagrant {
  class { 'vagrant':
    ensure  => present,
    version => '2.0.2',
  }
  vagrant::plugin { 'vagrant-vbguest':
    user => 'vagrant',
  }
  vagrant::plugin { 'vagrant-cachier':
    user => 'vagrant',
  }
}
