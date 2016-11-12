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
  ]: ensure => latest,
}


