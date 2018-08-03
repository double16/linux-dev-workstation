#
# Installs Node.js, tools and packages
#
class private::my_node {
  file { '/tmp/vagrant-cache/nodenv':
    ensure => directory,
    owner  => 'vagrant',
    group  => 'vagrant',
  }
  ->file_line { 'NODE_BUILD_CACHE_PATH':
    path  => '/etc/environment',
    line  => 'NODE_BUILD_CACHE_PATH=/tmp/vagrant-cache/nodenv',
    match => '^NODE_BUILD_CACHE_PATH\=',
  }
  ->class { '::nodenv':
    install_dir => '/opt/nodenv',
    #owner       => 'vagrant',
    group       => 'vagrant',
    latest      => false,
    require     => Class['private::git_from_source'],
  }

  nodenv::plugin { 'nodenv/node-build': }
  nodenv::plugin { 'nodenv/nodenv-each': }
  nodenv::plugin { 'nodenv/nodenv-package-json-engine': }

  $node_config = lookup('node', Hash)
  $node_versions = $node_config['versions']

  $node_versions.each |$item| {
    nodenv::build { $item['version']:
      global => pick($item['global'], false),
    }
  }

  $node_config['packages'].each |$package| {
    $node_versions.each |$item| {
      $version = $item['version']
      nodenv::package { "${package} on ${version}":
        package      => $package,
        node_version => $version,
      }
    }
  }

  Nodenv::Package<| |>
  ~>exec { 'vagrant owns nodenv':
    command => 'find /opt/nodenv -not -group vagrant -print0 | xargs -r0 chgrp vagrant && find /opt/nodenv -type d -print0 | xargs -r0 chmod g+ws',
    path    => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
  }

  File<| title == '/opt/nodenv'
    or title == '/opt/nodenv/plugins'
    or title == '/opt/nodenv/shims'
    or title == '/opt/nodenv/versions'
    |> {
      mode => '2775',
    }
}
