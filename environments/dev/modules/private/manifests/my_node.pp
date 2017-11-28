#
# Installs Node.js, tools and packages
#
class private::my_node {
  $node_lts = '8.9.1'
  $node_latest = '9.2.0'

  class { '::nodenv':
    install_dir => '/opt/nodenv',
    latest      => true,
  }

  nodenv::plugin { 'nodenv/node-build': }
  nodenv::plugin { 'nodenv/nodenv-each': }
  nodenv::plugin { 'nodenv/nodenv-package-json-engine': }

  nodenv::build { $node_lts: global => true }
  nodenv::build { $node_latest: }

  [ 'grunt', 'typescript', 'tern' ].each |$package| {
    nodenv::package { "${package} on LTS":
      package      => $package,
      node_version => $node_lts,
    }
    nodenv::package { "${package} on latest":
      package      => $package,
      node_version => $node_latest,
    }
  }
}
