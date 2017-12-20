# Joyent Triton CLI
# From https://docs.joyent.com/public-cloud/api-access/cloudapi
class private::triton {
  nodenv::package { 'triton on LTS':
    package      => 'triton',
    node_version => $::private::my_node::node_lts,
  }
  ->nodenv::package { 'triton on latest':
    package      => 'triton',
    node_version => $::private::my_node::node_latest,
  }
  ->exec {'triton completion':
    command     => 'nodenv rehash && triton completion > /etc/bash_completion.d/triton',
    creates     => '/etc/bash_completion.d/triton',
    path        => ['/bin','/usr/bin','/opt/nodenv/bin','/opt/nodenv/shims'],
    environment => ['HOME=/root'],
  }
}
