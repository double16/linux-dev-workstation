class my_vagrant {
  class { 'vagrant':
    version => '1.9.3',
  }
  vagrant::plugin { 'vagrant-vbguest':
    user => 'vagrant',
  }
  vagrant::plugin { 'vagrant-cachier':
    user => 'vagrant',
  }
}
