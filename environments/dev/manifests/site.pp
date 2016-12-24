include epel
include ius
include augeas

Class['epel'] -> Package<| |>
Class['ius'] -> Package<| |>

yum::plugin { 'replace':
  ensure => present,
}

yum::group { 'Development Tools':
  ensure => present,
}

yum::group { 'Xfce':
  ensure => present,
}

package { 'xorg*':
  ensure => present,
}->
file { '/etc/xorg.conf':
  ensure  => file,
  content => '
Section "ServerFlags"
  Option "AIGLX" "false"
EndSection
',
}

exec { 'graphical runlevel':
  path    => '/bin:/sbin:/usr/bin:/usr/sbin',
  command => 'systemctl set-default graphical.target',
  unless  => 'systemctl get-default | grep -q graphical',
}

#yum::group { 'GNOME Desktop':
#  ensure => present,
#}

package { [
    'asciidoc',
    'dos2unix',
    'htop',
    'iftop',
    'subversion',
    'wget',
    'xz',
    'psmisc',
    'git2u-all',
    'sqlite',
    #'rancher-compose',
    'pandoc',
    'tmux',
    'jq',
    'exiv2',
    'ansible',
    'firefox',
    'chromium',
    'chrome-remote-desktop',
    'java-1.8.0-openjdk-devel',
    'docker',
    'unzip',
    'mlocate',
    'rsync',
    'gparted',
    'lsof',
    'nmap-ncat',
  ]: ensure => present,
}

Archive::Download {
  follow_redirects => true,
}

include virtualbox
include my_vim
include my_ruby
include my_vagrant
include idea
include netbeans
include svn

class { 'sdkman' :
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
  version    => '2.4.7',
  is_default => true,
}

file { '/home/vagrant/.config':
  ensure => directory,
}

file { '/home/vagrant/.config/xfce4':
  ensure  => directory,
  recurse => remote,
  source  => 'file:///tmp/vagrant-puppet/environments/dev/files/dotconfig/xfce4',
}

file { '/home/vagrant/.config/git':
  ensure => directory,
}

file { '/home/vagrant/.config/git/ignore':
  ensure => file,
  source => 'file:///tmp/vagrant-puppet/environments/dev/files/gitignore',
}

