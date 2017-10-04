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
  ->archive { "git-${version}":
    url              => "https://github.com/git/git/archive/v${version}.tar.gz",
    target           => '/usr/src',
    extension        => 'tar.gz',
    checksum         => false,
    digest_string    => '09abc168f62992a86bab45fcdb7f4fc41baa3f1973e1fb663dc563d5ad94766a',
    digest_type      => 'sha256',
    follow_redirects => true,
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
