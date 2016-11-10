include epel

yum::group { 'Development Tools':
  ensure => present,
}

yum::group { 'Xfce':
  ensure => present,
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
    'watch',
    'xz',
    'pstree',
    'randomize-lines',
    'git',
    'git-flow',
    'git-lfs',
    'sqlite',
    'rancher-compose',
    'pandoc',
    'tmux',
    'jq',
    'exif',
    'ansible',
    'firefox',
    'transmission',
  ]: ensure => latest,
}


