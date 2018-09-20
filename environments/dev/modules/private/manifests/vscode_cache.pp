#
# Visual Studio Code IDE plugin caching
#
class private::vscode_cache($extension_path = '/home/vagrant/.vscode/extensions') {
  $cache_path = '/tmp/vagrant-cache/vscode-extensions'

  file { $cache_path:
    ensure => directory,
    mode   => '0777',
    owner  => 'vagrant',
    group  => 'vagrant',
  }

  exec { 'vscode expire cache':
    command => "/usr/bin/find ${cache_path} -maxdepth 1 -mtime +30 | xargs -r rm -rf",
    user    => 'vagrant',
    require => [ File[$cache_path] ],
  }
  ->exec { 'vscode install from cache':
    command => "/usr/bin/rsync -r --size-only --chown vagrant:vagrant ${cache_path}/ ${extension_path}/",
    user    => 'vagrant',
    timeout => 0,
    require => [ File[$cache_path], File[$extension_path], Package['rsync'] ],
  }

  exec { 'vscode populate cache':
    command     => "/usr/bin/rsync -r --size-only --delete ${extension_path}/ ${cache_path}/",
    user        => 'vagrant',
    timeout     => 0,
    refreshonly => true,
    require     => [ File[$cache_path], File[$extension_path], Package['rsync'] ],
    onlyif      => "/usr/bin/mountpoint /tmp/vagrant-cache",
  }
}
