# Joyent Triton CLI
# From https://docs.joyent.com/public-cloud/api-access/cloudapi
class private::triton {
  $triton_node_version = lookup('node', Hash)['versions']
    .filter |$item| { $item['global'] }
    .map |$item| { $item['version'] }[0]

  nodenv::package { 'triton':
    package      => 'triton',
    version      => '6.0.0',
    node_version => $triton_node_version,
    # node-gyp takes a long time, it is compiling the native bindings for node
    timeout      => 7200,
  }
  ->exec {'triton completion':
    command     => "/opt/nodenv/versions/${triton_node_version}/bin/triton completion > /etc/bash_completion.d/triton",
    creates     => '/etc/bash_completion.d/triton',
    path        => ['/bin','/usr/bin','/opt/nodenv/bin','/opt/nodenv/shims'],
    environment => ['HOME=/root'],
  }
}
