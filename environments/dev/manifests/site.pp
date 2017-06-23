include epel
include ius
include augeas

Class['epel'] -> Package<| |>
Class['ius'] -> Package<| |>

file { '/tmp/vagrant-cache':
  ensure => directory,
  mode   => '0777',
  owner  => 'vagrant',
  group  => 'vagrant',
}

yum::plugin { 'replace':
  ensure => present,
}

yum::group { 'Development Tools':
  ensure => present,
}
->exec { 'yum replace -y git --replace-with=git2u-all':
  unless  => 'yum list installed git2u-core',
  path    => '/bin:/sbin:/usr/bin:/usr/sbin',
  require => Package['git'],
}
->Package<| title == 'alien' |>
->Exec<| title == 'vboxdrv' |>


yum::group { 'X Window System':
  ensure => present,
}
->file { '/etc/xorg.conf':
  ensure  => file,
  content => '
Section "ServerFlags"
  Option "AIGLX" "false"
EndSection
',
}
->exec { 'yum-groupinstall-Xfce':
  command => "yum -y groupinstall --skip-broken 'Xfce'",
  unless  => "yum grouplist hidden 'Xfce' | egrep -i '^Installed.+Groups:$'",
  timeout => undef,
  path    => '/bin:/usr/bin:/sbin:/usr/sbin',
}
# 2017-05-17 xfce4-mixer has a broken dependency, so we're using the above
#->yum::group { 'Xfce':
#  ensure => present,
#}

exec { 'graphical runlevel':
  path    => '/bin:/sbin:/usr/bin:/usr/sbin',
  command => 'systemctl set-default graphical.target',
  unless  => 'systemctl get-default | grep -q graphical',
  require => Yum::Group['X Window System'],
}

#yum::group { 'GNOME Desktop':
#  ensure => present,
#}

package { 'python2-pip':
  ensure => present,
}->Package<| provider == 'pip' |>

package { [
    'asciidoc',
    'dos2unix',
    'htop',
    'iftop',
    'subversion',
    'wget',
    'xz',
    'psmisc',
    'sqlite',
    #'rancher-compose', # https://github.com/rancher/rancher-compose/releases
    'pandoc',
    'tmux',
    'jq',
    'exiv2',
    'ansible',
    'firefox',
    'chromium',
    'chrome-remote-desktop',
    'java-1.8.0-openjdk-devel',
    'unzip',
    'mlocate',
    'rsync',
    'gparted',
    'lsof',
    'nmap-ncat',
    'maven',
    'freerdp',
    'alien',
  ]: ensure => present,
}

Archive {
  src_target => '/tmp/vagrant-cache',
}

Archive::Download {
  follow_redirects => true,
}

unless $::virtual == 'docker' {
  include virtualbox
  package { "kernel-devel-${::kernelrelease}": }
  ->Exec<| title == 'vboxdrv' |>
}

include my_vim
include my_ruby
include my_node
include my_vagrant
include idea
include netbeans
include svn
include hipchat
include kitematic
include proxy

file { '/etc/profile.d/java.sh':
  ensure  => file,
  owner   => 0,
  group   => 'root',
  mode    => '0755',
  content => 'export JAVA_HOME=/etc/alternatives/java_sdk_1.8.0',
}

file { '/home/vagrant/.ssh':
  ensure => directory,
  owner  => 'vagrant',
  group  => 'vagrant',
  mode   => '0700',
}

file { '/home/vagrant/.ssh/config':
  ensure => file,
  owner  => 'vagrant',
  group  => 'vagrant',
  mode   => '0644',
}
->file_line { 'ssh user':
  ensure => present,
  path   => '/home/vagrant/.ssh/config',
  line   => "User ${::host_username}",
  match  => '^User\ ',
}

class { 'sdkman' :
}->
file { '/home/vagrant/.sdkman':
  ensure => link,
  target => '/root/.sdkman',
}->
file { '/etc/profile.d/sdkman.sh':
  ensure  => file,
  owner   => 0,
  group   => 'root',
  mode    => '0755',
  content => '[[ -s "/root/.sdkman/bin/sdkman-init.sh" ]] && source "/root/.sdkman/bin/sdkman-init.sh"',
}

exec { 'chmod 0755 /root/.sdkman':
  path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
  refreshonly => true,
  subscribe   => Class['sdkman'],
} -> Sdkman::Package<| |>

exec { 'chmod 0755 /root':
  path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
  refreshonly => true,
  subscribe   => Class['sdkman'],
} -> Sdkman::Package<| |>

sdkman::package { 'groovy':
  ensure     => present,
  version    => '2.4.11',
  is_default => true,
}

sdkman::package { 'gradle':
  ensure     => present,
  version    => '3.5',
  is_default => true,
}

sdkman::package { 'grails':
  ensure     => present,
  version    => '2.5.6',
  is_default => true,
}


file { '/usr/local/src':
  ensure => 'directory',
  owner  => 0,
  group  => 'vagrant',
  mode   => '0775',
}

file { '/home/vagrant/.config':
  ensure => directory,
  owner  => 'vagrant',
  group  => 'vagrant',
  mode   => '0755',
}

file { '/home/vagrant/.config/xfce4':
  ensure  => directory,
  recurse => remote,
  owner   => 'vagrant',
  group   => 'vagrant',
  source  => 'file:///tmp/vagrant-puppet/environments/dev/files/dotconfig/xfce4',
}

file { '/home/vagrant/.config/git':
  ensure => directory,
}

file { '/home/vagrant/.config/git/ignore':
  ensure => file,
  source => 'file:///tmp/vagrant-puppet/environments/dev/files/gitignore',
}

file { '/home/vagrant/Workspace':
  ensure => directory,
  owner  => 'vagrant',
  group  => 'vagrant',
}

unless $::virtual == 'docker' {
  package { 'docker':
    ensure => present,
  }
  ->service { 'docker':
    ensure => running,
    enable => true,
  }
  exec { 'docker options':
    path    => ['/bin','/sbin','/usr/bin','/usr/sbin'],
    command => "sed -i \"s/OPTIONS='/OPTIONS='--group=vagrant /\" /etc/sysconfig/docker",
    unless  => 'grep -q group=vagrant /etc/sysconfig/docker',
    require => Package['docker'],
    notify  => Service['docker'],
  }
}

package { 'docker-compose':
  ensure   => present,
  provider => 'pip',
}

file { '/usr/local/bin/docker-clean':
  ensure => file,
  mode   => '0755',
  source => 'file:///tmp/vagrant-puppet/environments/dev/files/docker-clean.sh',
}

