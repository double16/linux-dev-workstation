#
# Install vagrant and generally useful plugins
#
class private::my_vagrant {
  $version = lookup('vagrant', Hash)['version']

  $vagrant_plugins = [
    'vagrant-cachier',
    'vagrant-aws',
    'vagrant-azure',
    #'vagrant-google', # deps need Ruby >= 2.5.0, vagrant 2.2.x uses Ruby 2.4.x
    #'vagrant-joyent',
    'vagrant-sshfs',
  ]

  $vagrant_plugins_hypervisor = [
    'vagrant-vbguest',
    'vagrant-disksize',
  ]

  package { [ 'fuse-sshfs' ]: }

  $vagrant_plugins_sum = sha256(join($vagrant_plugins + $vagrant_plugins_hypervisor, ','))
  $cache_file = "/tmp/vagrant-cache/vagrant-plugins-${vagrant_plugins_sum}.tgz"
  $cache_dir = '/home/vagrant/.vagrant.d/gems/2.4.6'

  file { ['/home/vagrant/.vagrant.d', '/home/vagrant/.vagrant.d/gems', $cache_dir]:
    ensure  => directory,
    owner   => 'vagrant',
    group   => 'vagrant',
    mode    => '0775',
    require => Class['vagrant'],
  }
  ->exec { 'restore cache for vagrant plugins':
    command => "/usr/bin/tar xzf \"${cache_file}\" -C ${cache_dir}",
    onlyif  => "/usr/bin/find \"${cache_file}\" -mtime -30 | grep -q .",
    creates => "${cache_dir}/cache/vagrant-cachier-1.2.1.gem",
    require => Class['vagrant'],
  }
  ->Vagrant::Plugin<| |>

  Vagrant::Plugin<| |>
  ~>exec { 'save cache for vagrant plugins':
    command     => "/bin/rm -f \"${cache_file}\" ; /usr/bin/tar czf \"${cache_file}\" -C ${cache_dir} cache",
    refreshonly => true,
    require     => File['/tmp/vagrant-cache'],
    onlyif      => '/usr/bin/mountpoint /tmp/vagrant-cache',
  }

  class { 'vagrant':
    ensure  => present,
    version => $version,
  }
  vagrant::plugin { $vagrant_plugins:
    user => 'vagrant',
  }

unless $::virtual == 'docker' or $::virtual =~ /xen.*/ {
    if str2bool($::packer) {
      $libvirtd_enable = false
    } else {
      $libvirtd_enable = undef
    }

    vagrant::plugin { $vagrant_plugins_hypervisor:
      user => 'vagrant',
    }
    # FIXME:
    # package { [
    #   'libvirt',
    #   'libvirt-devel',
    #   ]:
    # }
    # ->service { 'libvirtd':
    #   enable => $libvirtd_enable,
    # }
    # ->vagrant::plugin { 'vagrant-libvirt':
    #   user => 'vagrant',
    # }
  }
}
