# Joyent Triton CLI
# From https://docs.joyent.com/public-cloud/api-access/cloudapi
class private::triton {
  $triton_node_version = '6.11.5'

  nodenv::build { $triton_node_version: }

  nodenv::package { 'triton':
    package      => 'triton',
    version      => '5.5.0',
    node_version => $triton_node_version,
  }
  ->exec {'triton completion':
    command     => "/opt/nodenv/versions/${triton_node_version}/bin/triton completion > /etc/bash_completion.d/triton",
    creates     => '/etc/bash_completion.d/triton',
    path        => ['/bin','/usr/bin','/opt/nodenv/bin','/opt/nodenv/shims'],
    environment => ['HOME=/root'],
  }
}
