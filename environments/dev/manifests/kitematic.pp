class kitematic
{

nodenv::build { '4.1.1': }
nodenv::package { 'grunt on 4.1.1':
  package      => 'grunt',
  node_version => '4.1.1',
}->
exec { 'kitematic clone':
  path    => ['/bin','/sbin','/usr/bin','/usr/sbin'],
  command => 'git clone https://github.com/docker/kitematic.git /usr/local/src/kitematic',
  user    => 'vagrant',
  group   => 'vagrant',
  creates => '/usr/local/src/kitematic/.git',
  require => [ Package['docker'], Package['git'], File['/usr/local/src'] ],
}->
file { '/usr/local/src/kitematic/.node-version':
  ensure  => file,
  owner   => 'vagrant',
  group   => 'vagrant',
  content => '4.1.1',
}->
exec { 'kitematic npm install':
  path    => ['/bin','/sbin','/usr/bin','/usr/sbin','/opt/nodenv/shims','/opt/nodenv/bin'],
  cwd     => '/usr/local/src/kitematic',
  command => 'npm install',
  user    => 'vagrant',
  group   => 'vagrant',
  creates => '/usr/local/src/kitematic/node_modules/.bin/grunt',
  timeout => 0,
}->
exec { 'kitematic dist build':
  path    => ['/bin','/sbin','/usr/bin','/usr/sbin','/opt/nodenv/shims','/opt/nodenv/bin'],
  cwd     => '/usr/local/src/kitematic',
  command => 'su -l vagrant -c "cd /usr/local/src/kitematic && grunt --debug release"',
  unless  => 'ls /usr/local/src/kitematic/dist/*.rpm',
  timeout => 0,
}->
exec { 'kitematic install':
  path    => ['/bin','/sbin','/usr/bin','/usr/sbin','/opt/nodenv/shims','/opt/nodenv/bin'],
  cwd     => '/usr/local/src/kitematic',
  command => 'yum install -y /usr/local/src/kitematic/dist/*.rpm',
  creates => '/usr/bin/Kitematic',
  timeout => 0,
}

}

