stage { 'pre':
  before => Stage['main'],
}

class { '::private::security':
  stage => 'pre',
}

if $::virtual == 'docker' {
  Service {
    provider => 'supervisor',
  }
}

include ::augeas
include ::private::proxy

Package<| provider == 'yum' or provider == 'dnf' |> {
  install_options +> '--nogpgcheck',
}

exec { 'RPM Fusion Free':
  command => '/usr/bin/rpm -i --force --nodeps http://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-31.noarch.rpm && /usr/bin/rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-rpmfusion-free-fedora-31',
  creates => '/etc/yum.repos.d/rpmfusion-free.repo',
}
-> Package<| |>

package { ['cronie', 'cronie-anacron', 'crontabs']: }
->Cron<| |>

# Initial setup prompts for license acceptance
if $::virtual != 'docker' {
  service { ['initial-setup', 'initial-setup-text', 'initial-setup-graphical']:
    enable => false,
  }
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

unless $::virtual == 'docker' {
  package { 'dnf-automatic': }
}

yum::group { 'Development Tools':
  ensure  => present,
  timeout => 0,
}
->Package<| |>

yum::group { 'Xfce Desktop':
  ensure  => present,
  timeout => 3600,
}
->package { [
  'xfce4-clipman-plugin',
  'xfce4-screenshooter',
  'xfce4-screenshooter-plugin',
  'xfce4-whiskermenu-plugin',
  'xfce4-systemload-plugin',
  'xfce4-fsguard-plugin',
  ]: }

$autologin_default = $::virtual ? {
  'virtualbox' => present,
  'vmware'     => present,
  default      => absent,
}
$autologin_ensure = $::native_gui ? {
  true      => present,
  'true'    => present,
  false     => absent,
  'false'   => absent,
  default   => $autologin_default,
}
ini_setting { 'lightdm autologin enable':
  ensure  => $autologin_ensure,
  path    => '/etc/lightdm/lightdm.conf',
  section => 'Seat:*',
  setting => 'autologin-user-timeout',
  value   => '0',
  require => Yum::Group['Xfce Desktop'],
}
->ini_setting { 'lightdm autologin user':
  ensure  => $autologin_ensure,
  path    => '/etc/lightdm/lightdm.conf',
  section => 'Seat:*',
  setting => 'autologin-user',
  value   => 'vagrant',
  require => Yum::Group['Xfce Desktop'],
}

$systemd_default_target = $autologin_ensure ? {
  present => 'graphical.target',
  default => 'multi-user.target',
}
exec { 'graphical runlevel':
  path    => '/bin:/sbin:/usr/bin:/usr/sbin',
  command => "systemctl set-default ${systemd_default_target}",
  unless  => "systemctl get-default | grep -q ${systemd_default_target}",
  require => Yum::Group['Xfce Desktop'],
}

package { ['python3', 'python3-pip', 'python3-virtualenv']:
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
    'man-db',
    'asciidoc',
    'dos2unix',
    'htop',
    'iftop',
    'subversion',
    'wget',
    'xz',
    'psmisc',
    'sqlite',
    'bind-utils',
    #'rancher-compose', # https://github.com/rancher/rancher-compose/releases
    'pandoc',
    'tmux',
    'jq',
    'exiv2',
    'ansible',
    'firefox',
    'chrome-remote-desktop',
    'java-1.8.0-openjdk-devel',
    'mlocate',
    'rsync',
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
    'collectl',
    'net-tools',
    'cifs-utils',
    'samba',
    'puppet-bolt',
    'backintime-qt',
    'duplicity',
    'deja-dup',
    'cool-retro-term',
    'snapd',

    # For recording the screen via 'ffmpeg x11grab'
    'ffmpeg',
    'libvdpau',
    'libavdevice',

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
  creates => '/usr/local/bin/xml2json',
  require => [ Package['python3'], Class['private::proxy'], Ini_setting['pip proxy'] ],
}

package { 'unzip': }
->Archive<| |>

Archive {
  cleanup  => false,
}

class { '::git':
  package_name => 'git-all',
  package_manage => true,
}
->Package<| title == 'alien' |>
->Exec<| title == 'vboxdrv' |>

unless $::virtual == 'docker' or $::virtual =~ /xen.*/ {
  package { 'VirtualBox': }
  ->User<| title == 'vagrant' |> { groups +> 'vboxusers' }
}

include ::private::my_vim
include ::private::my_ruby
include ::private::my_node
include ::private::my_vagrant
include ::private::my_sdkman
include ::private::my_docker
include ::private::idea
#include ::private::netbeans  # netbeans is old, 2016, and vscode is superior
include ::private::slack
include ::private::dockstation
include ::private::clean
include ::private::rdp
include ::private::hashistack
include ::private::my_vcsrepos
include ::private::rlang
include ::private::pdk
include ::private::vscode
include ::private::pending_changes
#Takes ~1 hour: include ::private::triton
include ::private::aws
include ::private::azure
include ::private::googlecloud
include ::private::googlechrome
include ::private::iterm2
include ::private::circleci
include ::private::xfce4
include ::private::rust
include ::private::fb
include ::private::my_emacs
include ::private::zeal
include ::private::zsh

file { '/etc/profile.d/java.sh':
  ensure  => file,
  owner   => 0,
  group   => 'root',
  mode    => '0755',
  content => 'export JAVA_HOME=/etc/alternatives/java_sdk_1.8.0',
}

file { '/usr/local/sbin/disksize.sh':
  ensure  => file,
  owner   => 0,
  group   => 'root',
  mode    => '0755',
  source  => 'puppet:///modules/private/disksize.sh',
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
    require => Package['git-all'],
  }
}

unless empty($::user_email) {
  git::config { 'user.email':
    value   => $::user_email,
    user    => 'vagrant',
    scope   => 'global',
    require => Package['git-all'],
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

$user_shell = pick($::shell, lookup('shell::default'), 'bash')
user { 'root':
  shell => "/usr/bin/${user_shell}",
}
User<| title == 'vagrant' |> {
  shell => "/usr/bin/${user_shell}",
}
Package['zsh']
->User<| |>
