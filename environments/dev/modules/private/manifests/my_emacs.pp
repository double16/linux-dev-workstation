#
# Installs emacs and plugins
#
class private::my_emacs {
  $version = '25.3'

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
    'adobe-source-code-pro-fonts',
  ]: }
  ->archive { "/tmp/vagrant-cache/emacs-${version}.tar.gz":
    source        => "http://ftp.gnu.org/gnu/emacs/emacs-${version}.tar.gz",
    extract_path  => '/usr/src',
    extract       => true,
    creates       => "/usr/src/emacs-${version}",
    checksum      => 'f72c6a1b48b6fbaca2b991eed801964a208a2f8686c70940013db26cd37983c9',
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
    subscribe   => [ Vcsrepo['/home/vagrant/.emacs.d'], File['/home/vagrant/.spacemacs'] ],
  }
}
