#
# Installs emacs and plugins
#
class private::my_emacs {
  $version = lookup('emacs', Hash)['version']
  $checksum = lookup('emacs', Hash)['checksum']
  $cache_file = "/tmp/vagrant-cache/emacs-${version}-built.tgz"
  $spacemacs_cache_file = "/tmp/vagrant-cache/spacemacs-${version}-built.tgz"

  package { [
    'libXpm',
    'libXpm-devel',
    'libXaw',
    'libXaw-devel',
    'libjpeg-turbo',
    'libjpeg-turbo-devel',
    'giflib',
    'giflib-devel',
    'libpng',
    'libpng-devel',
    'libtiff',
    'libtiff-devel',
    'gnutls-devel',
    'adobe-source-code-pro-fonts',
  ]: }
  ->archive { "/tmp/vagrant-cache/emacs-${version}.tar.gz":
    source        => "http://mirrors.kernel.org/gnu/emacs/emacs-${version}.tar.gz",
    extract_path  => '/usr/src',
    extract       => true,
    cleanup       => false,
    creates       => "/usr/src/emacs-${version}",
    checksum      => $checksum,
    checksum_type => 'sha256',
    require       => File['/tmp/vagrant-cache'],
  }
  ->exec { "configure emacs ${version}":
    path    => ['/bin','/sbin','/usr/bin','/usr/sbin','/usr/local/bin'],
    cwd     => "/usr/src/emacs-${version}",
    command => "/usr/src/emacs-${version}/configure --prefix=/usr",
    unless  => "grep -qF 'S[\"prefix\"]=\"/usr\"' /usr/src/emacs-${version}/config.status",
    require => Package['ncurses-devel'],
  }
  ->exec { "build emacs ${version}":
    path      => ['/bin','/sbin','/usr/bin','/usr/sbin','/usr/local/bin'],
    cwd       => "/usr/src/emacs-${version}",
    command   => 'make',
    creates   => "/usr/src/emacs-${version}/src/emacs",
    timeout   => 900,
    subscribe => Exec["configure emacs ${version}"],
  }
  ->exec { "install emacs ${version}":
    path      => ['/bin','/sbin','/usr/bin','/usr/sbin','/usr/local/bin'],
    cwd       => "/usr/src/emacs-${version}",
    command   => 'make install',
    unless    => "test -e /usr/bin/emacs && /usr/bin/emacs --version | grep -qF ${version}",
    subscribe => Exec["build emacs ${version}"],
  }

  if $::vagrant_cache_mounted {
    exec { "cache emacs ${version}":
      path      => ['/bin','/sbin','/usr/bin','/usr/sbin','/usr/local/bin'],
      cwd       => '/usr/src',
      command   => "tar czf ${cache_file} emacs-${version}",
      creates   => $cache_file,
      subscribe => Exec["build emacs ${version}"],
      require   => [ File['/tmp/vagrant-cache'], Exec["build emacs ${version}"] ],
    }
    exec { "restore emacs ${version}":
      path    => ['/bin','/sbin','/usr/bin','/usr/sbin','/usr/local/bin'],
      cwd     => '/usr/src',
      command => "tar xzpf ${cache_file}",
      creates => "/usr/src/emacs-${version}",
      onlyif  => "test -f ${cache_file}",
      require => [ File['/tmp/vagrant-cache'] ],
      before  => [ Archive["/tmp/vagrant-cache/emacs-${version}.tar.gz"] ],
    }
  }

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
    command     => 'pkill emacs ; emacs --daemon ; pkill emacs; true',
    provider    => 'shell',
    environment => [ 'HOME=/home/vagrant' ],
    user        => 'vagrant',
    group       => 'vagrant',
    cwd         => '/home/vagrant',
    refreshonly => true,
    timeout     => 1200,
    require     => [ Exec["install emacs ${version}"] ],
    subscribe   => [ Vcsrepo['/home/vagrant/.emacs.d'], File['/home/vagrant/.spacemacs'] ],
  }

  if $::vagrant_cache_mounted {
    exec { "cache spacemacs ${version}":
      path      => ['/bin','/sbin','/usr/bin','/usr/sbin','/usr/local/bin'],
      cwd       => '/home/vagrant',
      command   => "tar czf ${spacemacs_cache_file} .emacs.d",
      creates   => $spacemacs_cache_file,
      subscribe => Exec['spacemacs install'],
      require   => [ File['/tmp/vagrant-cache'], Exec['spacemacs install'] ],
    }
    exec { "restore spacemacs ${version}":
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
