class my_node {
  $node_lts = '6.10.1'
  $node_latest = '7.7.4'

  class { 'nodenv':
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
}
