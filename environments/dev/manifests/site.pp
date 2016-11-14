include epel

yum::group { 'Development Tools':
  ensure => present,
}

yum::group { 'Xfce':
  ensure => present,
}

package { 'xorg*':
  ensure => latest,
}->
file { '/etc/xorg.conf':
  ensure => file,
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
#  ensure => latest,
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
    'git',
    'gitflow',
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
  ]: ensure => latest,
}

Archive::Download {
  follow_redirects => true,
}

#class { 'idea::ultimate':
#  version => '2016.2.5',
#}

class { 'vagrant':
  version => '1.8.7',
}
vagrant::plugin { 'vagrant-vbguest':
  user => 'vagrant',
}
vagrant::plugin { 'vagrant-cachier':
  user => 'vagrant',
}

include virtualbox
include my_vim

class { 'sdkman' :
}

sdkman::package { 'groovy':
  version    => '2.4.7',
  is_default => true,
  ensure     => present
}

