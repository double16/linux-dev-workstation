#
# Ruby Versions and gems
#
class private::my_ruby {
  file { '/tmp/vagrant-cache/rbenv':
    ensure => directory,
    owner  => 'vagrant',
    group  => 'vagrant',
  }
  ->file_line { 'RUBY_BUILD_CACHE_PATH':
    path  => '/etc/environment',
    line  => 'RUBY_BUILD_CACHE_PATH=/tmp/vagrant-cache/rbenv',
    match => '^RUBY_BUILD_CACHE_PATH\=',
  }
  ->class { '::rbenv':
    install_dir => '/opt/rbenv',
    latest      => false,
    #owner       => 'vagrant',
    group       => 'vagrant',
    require     => Class['private::git_from_source'],
  }
  ->Rbenv::Build<| |>

  rbenv::plugin { 'rbenv/ruby-build': latest => true }
  rbenv::plugin { 'sstephenson/ruby-build': latest => true }

  Rbenv::Build<| |> {
    env => ['RUBY_BUILD_CACHE_PATH=/tmp/vagrant-cache/rbenv'],
  }

  $ruby_config = lookup('ruby', Hash)
  $ruby_versions = $ruby_config['versions']
  $ruby_ver = $ruby_versions.filter |$item| { $item['global'] == true }[0]['version']

  Exec <| title == "rbenv-ownit-${ruby_ver}" |> -> Rbenv::Gem<| |>

  $ruby_versions.each |$item| {
    $ver = $item['version']
    $cache = "/tmp/vagrant-cache/rbenv/built-${ver}.tgz"
    exec { "Unarchive Ruby ${ver}":
      command => "/usr/bin/tar xpzf ${cache} -C /opt/rbenv/versions",
      onlyif  => "/usr/bin/test -f ${cache}",
      creates => "/opt/rbenv/versions/${ver}",
      require => File['/opt/rbenv/versions'],
    }
    ->rbenv::build { $ver:
      global => pick($item['global'], false),
    }
    ~>exec { "Archive Ruby ${ver}":
      command     => "/usr/bin/tar czf ${cache} -C /opt/rbenv/versions ${ver}",
      refreshonly => true,
      require     => File['/tmp/vagrant-cache/rbenv'],
    }
    ->Rbenv::Gem<| ruby_version == $ver and gem != 'bundler' |>
  }

  Rbenv::Gem {
    ruby_version => $ruby_ver,
  }

  rbenv::gem { 'rake': }
  rbenv::gem { 'librarian-puppet':
    version => '>=3.0.0',
  }
  rbenv::gem { 'librarianp':
    version => '>=0.6.4',
  }
  rbenv::gem { 'puppet-lint': }
  rbenv::gem { 'generate-puppetfile': }

  package { 'augeas-devel': }
  ->rbenv::gem { 'ruby-augeas': }

  Rbenv::Gem<| |>
  ~>exec { 'vagrant owns rbenv':
    command => 'find /opt/rbenv -not -group vagrant -print0 | xargs -r0 chgrp vagrant && find /opt/rbenv -type d -print0 | xargs -r0 chmod g+ws',
    path    => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
  }

  File<| title == '/opt/rbenv'
    or title == '/opt/rbenv/plugins'
    or title == '/opt/rbenv/shims'
    or title == '/opt/rbenv/versions'
    |> {
      mode => '2775',
    }
}
