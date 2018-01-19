# Joyent Triton CLI
# From https://docs.joyent.com/public-cloud/api-access/cloudapi
class private::triton {
  nodenv::package { 'triton on LTS':
    package      => 'triton',
    version      => '5.4.0',
    node_version => $::private::my_node::node_lts,
  }
  ->exec {'triton completion':
    command     => 'nodenv rehash && triton completion > /etc/bash_completion.d/triton',
    creates     => '/etc/bash_completion.d/triton',
    path        => ['/bin','/usr/bin','/opt/nodenv/bin','/opt/nodenv/shims'],
    environment => ['HOME=/root'],
  }
}
