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
  ->archive { "/tmp/vagrant-cache/git-${version}":
    source        => "https://github.com/git/git/archive/v${version}.tar.gz",
    extract_path  => '/usr/src',
    extract       => true,
    creates       => "/usr/src/git-${version}",
    checksum      => '09abc168f62992a86bab45fcdb7f4fc41baa3f1973e1fb663dc563d5ad94766a',
    checksum_type => 'sha256',
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
