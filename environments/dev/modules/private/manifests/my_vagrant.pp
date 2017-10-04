class private::my_vagrant {
  class { 'vagrant':
    ensure  => present,
    version => '1.9.5',
  }
  vagrant::plugin { 'vagrant-vbguest':
    user => 'vagrant',
  }
  vagrant::plugin { 'vagrant-cachier':
    user => 'vagrant',
  }
}
