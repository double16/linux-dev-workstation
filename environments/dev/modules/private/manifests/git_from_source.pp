# Installs a specific version of git from source
class private::git_from_source($version) {
  package { [
    'autoconf',
    'libcurl-devel',
    'expat-devel',
    'gcc',
    'gettext-devel',
    'kernel-headers',
    'openssl-devel',
    'perl-devel',
    'zlib-devel']: }
  ->archive { "/tmp/vagrant-cache/git-${version}.tar.gz":
    source       => "https://github.com/git/git/archive/v${version}.tar.gz",
    extract_path => '/usr/src',
    extract      => true,
    cleanup      => false,
    creates      => "/usr/src/git-${version}",
    require      => File['/tmp/vagrant-cache'],
  }
  ->exec { "make configure git ${version}":
    path    => ['/bin','/sbin','/usr/bin','/usr/sbin','/usr/local/bin'],
    cwd     => "/usr/src/git-${version}",
    command => 'make configure',
    creates => "/usr/src/git-${version}/configure",
  }
  ->exec { "configure git ${version}":
    path    => ['/bin','/sbin','/usr/bin','/usr/sbin','/usr/local/bin'],
    cwd     => "/usr/src/git-${version}",
    command => "/usr/src/git-${version}/configure --prefix=/usr",
    unless  => "grep -qF 'S[\"prefix\"]=\"/usr\"' /usr/src/git-${version}/config.status",
  }
  ->exec { "build git ${version}":
    path      => ['/bin','/sbin','/usr/bin','/usr/sbin','/usr/local/bin'],
    cwd       => "/usr/src/git-${version}",
    command   => 'make',
    creates   => "/usr/src/git-${version}/git",
    timeout   => 900,
    subscribe => Exec["configure git ${version}"],
  }
  ->exec { "install git ${version}":
    path      => ['/bin','/sbin','/usr/bin','/usr/sbin','/usr/local/bin'],
    cwd       => "/usr/src/git-${version}",
    command   => 'make install',
    unless    => "/usr/bin/git --version | grep -qF ${version}",
    subscribe => Exec["build git ${version}"],
  }
}
