class private::my_vagrant {
  class { 'vagrant':
    ensure  => present,
    version => '2.0.0',
  }
  vagrant::plugin { 'vagrant-vbguest':
    user => 'vagrant',
  }
  vagrant::plugin { 'vagrant-cachier':
    user => 'vagrant',
  }
}
