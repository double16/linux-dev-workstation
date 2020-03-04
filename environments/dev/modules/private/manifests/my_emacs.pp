#
# Installs emacs and plugins
#
class private::my_emacs {
  $spacemacs_cache_file = "/tmp/vagrant-cache/spacemacs-built.tgz"

  package { 'emacs': }

  vcsrepo { '/home/vagrant/.emacs.d':
    ensure   => present,
    user     => 'vagrant',
    group    => 'vagrant',
    provider => git,
    source   => 'https://github.com/syl20bnr/spacemacs.git',
  }

  file { '/home/vagrant/.spacemacs':
    ensure  => file,
    owner   => 'vagrant',
    group   => 'vagrant',
    source  => 'puppet:///modules/private/dotconfig/spacemacs',
    replace => false,
  }

  exec { 'spacemacs install':
    path        => ['/bin','/sbin','/usr/bin','/usr/sbin','/usr/local/bin'],
    command     => 'pkill emacs ; emacs --daemon ; pkill emacs; pkill gpg-agent; sleep 5s; true',
    provider    => 'shell',
    environment => [ 'HOME=/home/vagrant' ],
    user        => 'vagrant',
    group       => 'vagrant',
    cwd         => '/home/vagrant',
    refreshonly => true,
    timeout     => 2400,
    require     => [ Package['emacs'] ],
    subscribe   => [ Vcsrepo['/home/vagrant/.emacs.d'], File['/home/vagrant/.spacemacs'] ],
  }

  if $::vagrant_cache_mounted {
    exec { "cache spacemacs":
      path      => ['/bin','/sbin','/usr/bin','/usr/sbin','/usr/local/bin'],
      cwd       => '/home/vagrant',
      command   => "tar czf ${spacemacs_cache_file} .emacs.d",
      creates   => $spacemacs_cache_file,
      subscribe => Exec['spacemacs install'],
      require   => [ File['/tmp/vagrant-cache'], Exec['spacemacs install'] ],
    }
    exec { "restore spacemacs":
      path    => ['/bin','/sbin','/usr/bin','/usr/sbin','/usr/local/bin'],
      cwd     => '/home/vagrant',
      command => "tar xzpf ${spacemacs_cache_file}",
      creates => '/home/vagrant/.emacs.d',
      onlyif  => "test -f ${spacemacs_cache_file}",
      require => [ File['/tmp/vagrant-cache'] ],
      before  => [ Vcsrepo['/home/vagrant/.emacs.d'] ],
    }
  }
}
