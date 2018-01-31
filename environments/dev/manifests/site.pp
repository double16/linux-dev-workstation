stage { 'pre':
  before => Stage['main'],
}

class { '::private::security':
  stage => 'pre',
}

include ::epel
include ::ius
include ::augeas
include ::private::proxy

Class['epel'] -> Package<| |>
Class['ius'] -> Package<| |>

# Initial setup prompts for license acceptance
service { ['initial-setup', 'initial-setup-text', 'initial-setup-graphical']:
  enable => false,
}

if $::timezone {
  notice("Timezone is ${::timezone}")
  class { 'timezone':
      timezone => $::timezone,
  }
}

file { '/tmp/vagrant-cache':
  ensure => directory,
  mode   => '0777',
  owner  => 'vagrant',
  group  => 'vagrant',
}

$service_running = $::virtual ? {
  /docker/ => 'stopped',
  default  => 'running',
}

if $::virtual == 'docker' {
  class { '::yum_cron':
    apply_updates  => true,
    service_ensure => false,
    service_enable => false,
  }
} else {
  class { '::yum_cron':
    apply_updates => true,
  }
}

yum::plugin { 'replace':
  ensure => present,
}

yum::group { 'Development Tools':
  ensure => present,
}
->package { ['git2u-all','git2u']: ensure => purged, }
->class { '::private::git_from_source': version => '2.13.5', }
->Package<| title == 'alien' |>
->Exec<| title == 'vboxdrv' |>

Exec<| title == 'yum-groupinstall-X Window System' |> {
  timeout => 0,
}

yum::group { 'X Window System':
  ensure => present,
}
->file { '/etc/xorg.conf':
  ensure  => absent,
}
->exec { 'yum-groupinstall-Xfce':
  command => "yum -y groupinstall --skip-broken 'Xfce'",
  unless  => "yum grouplist hidden 'Xfce' | egrep -i '^Installed.+Groups:$'",
  timeout => 0,
  path    => '/bin:/usr/bin:/sbin:/usr/sbin',
}
->file_line { 'gdm autologin enable':
  path  => '/etc/gdm/custom.conf',
  line  => 'AutomaticLoginEnable=true',
  after => '\[daemon\]',
  match => '^AutomaticLoginEnable=.*',
}
->file_line { 'gdm autologin user':
  path  => '/etc/gdm/custom.conf',
  line  => 'AutomaticLogin=vagrant',
  after => '\[daemon\]',
  match => '^AutomaticLogin=.*',
}

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
}
->file { '/etc/xdg':
  ensure => directory,
  owner  => 0,
  group  => 'root',
  mode   => '0755',
}
->file { '/etc/xdg/pip':
  ensure => directory,
  owner  => 0,
  group  => 'root',
  mode   => '0755',
}
->file { '/etc/xdg/pip/pip.conf':
  ensure => file,
  owner  => 0,
  group  => 'root',
  mode   => '0644',
}
->Package<| provider == 'pip' |>

package { [
    'man-pages',
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
    'mlocate',
    'rsync',
    'gparted',
    'lsof',
    'nmap-ncat',
    'socat',
    'tcpdump',
    'maven',
    'freerdp',
    'alien',
    'which',
    'tree',
    'im-chooser',
    'go',
    'gnupg',
    'gkrellm',
    'gkrellm-top',

    'ffmpeg',
    'libvdpau',
    'libavcodec52',
    'libavcodec53',
    'libavcodec54',
    'libavcodec55',
    'libavdevice52',
    'libavdevice53',
    'libavdevice54',
    'libavdevice55',
    'libavfilter1',
    'libavfilter2',
    'libavfilter3',
    'libavfilter4',
    'libavformat52',
    'libavformat53',
    'libavformat54',
    'libavformat55',
    'libavutil50',
    'libavutil51',
    'libavutil52',
    'libpostproc51',
    'libpostproc52',
    'libswresample0',
    'libswscale0',
    'libswscale2',

  ]: ensure => present,
}

package { [
    'yq',
  ]:
  ensure   => present,
  provider => 'pip',
}

exec { 'xml2json':
  path    => ['/bin','/sbin','/usr/bin','/usr/sbin'],
  command => 'pip install https://github.com/hay/xml2json/zipball/master',
  creates => '/usr/bin/xml2json',
  require => [ Package['python2-pip'], Class['private::proxy'], Ini_setting['pip proxy'] ],
}

package { 'unzip': }
->Archive<| |>

Archive {
  cleanup  => false,
}

class { '::git':
  package_manage => false,
}

unless $::virtual == 'docker' or $::virtual =~ /xen.*/ {
  class { '::virtualbox':
    version => '5.2',
  }
  package { "kernel-devel-${::kernelrelease}": }
  ->Exec<| title == 'vboxdrv' |>
}

include ::private::my_vim
include ::private::my_ruby
include ::private::my_node
include ::private::my_vagrant
include ::private::my_sdkman
include ::private::my_docker
include ::private::idea
include ::private::netbeans
include ::private::svn
include ::private::hipchat
include ::private::slack
include ::private::kitematic
include ::private::clean
include ::private::vnc
include ::private::hashistack
include ::private::my_vcsrepos
include ::private::rlang
include ::private::pdk
include ::private::vscode
include ::private::pending_changes
include ::private::triton
include ::private::aws
include ::private::azure
include ::private::googlecloud
include ::private::iterm2

# emacs won't compile under docker because we don't have permission to disable ASLR and exec-shield
unless $::virtual == 'docker' {
  include ::private::my_emacs
}

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

unless str2bool($::packer) {
  file_line { 'ssh user':
    ensure  => present,
    path    => '/home/vagrant/.ssh/config',
    line    => "User ${::host_username}",
    match   => '^User\ ',
    require => File['/home/vagrant/.ssh/config'],
  }

  ssh_keygen { 'vagrant': }
}

unless empty($::user_name) {
  git::config { 'user.name':
    value   => $::user_name,
    user    => 'vagrant',
    scope   => 'global',
    require => Class['Private::Git_from_source'],
  }
}

unless empty($::user_email) {
  git::config { 'user.email':
    value   => $::user_email,
    user    => 'vagrant',
    scope   => 'global',
    require => Class['Private::Git_from_source'],
  }
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
  source  => 'puppet:///modules/private/dotconfig/xfce4',
}

file { '/home/vagrant/.config/git':
  ensure => directory,
}

file { '/home/vagrant/.config/git/ignore':
  ensure => file,
  source => 'puppet:///modules/private/gitignore',
}

file { '/home/vagrant/Workspace':
  ensure => directory,
  owner  => 'vagrant',
  group  => 'vagrant',
}

