#
# Install vagrant and generally useful plugins
#
class private::my_vagrant {
  $version = lookup('vagrant', Hash)['version']

  package { [ 'fuse-sshfs' ]: }

  class { 'vagrant':
    ensure  => present,
    version => $version,
  }
  vagrant::plugin { [
    'vagrant-cachier',
    'vagrant-aws',
    'vagrant-azure',
    'vagrant-google',
    'vagrant-joyent',
    'vagrant-sshfs',
    ]:
    user => 'vagrant',
  }

unless $::virtual == 'docker' or $::virtual =~ /xen.*/ {
    vagrant::plugin { [
      'vagrant-vbguest',
      'vagrant-disksize',
      ]:
      user => 'vagrant',
    }
    package { [
      'libvirt',
      'libvirt-devel',
      ]:
    }
    ->vagrant::plugin { 'vagrant-libvirt': 
      user => 'vagrant',
    }
  }
}
