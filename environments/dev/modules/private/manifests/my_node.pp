class private::my_node {
  $node_lts = '6.11.5'
  $node_latest = '8.8.1'

  class { '::nodenv':
    install_dir => '/opt/nodenv',
    latest      => true,
  }

  nodenv::plugin { 'nodenv/node-build': }
  nodenv::plugin { 'nodenv/nodenv-each': }
  nodenv::plugin { 'nodenv/nodenv-package-json-engine': }

  nodenv::build { $node_lts: global => true }
  nodenv::build { $node_latest: }

  nodenv::package { 'grunt on LTS':
    package      => 'grunt',
    node_version => $node_lts,
  }
  nodenv::package { 'grunt on latest':
    package      => 'grunt',
    node_version => $node_latest,
  }
  nodenv::package { 'typescript on LTS':
    package      => 'typescript',
    node_version => $node_lts,
  }
  nodenv::package { 'typescript on latest':
    package      => 'typescript',
    node_version => $node_latest,
  }
}
