#
# Installs iTerm2 integration
#
class private::iterm2 {
  package { 'php': }

  exec { 'iterm2 integration':
    path        => ['/bin','/sbin','/usr/bin','/usr/sbin','/usr/local/bin'],
    command     => 'su -c "/usr/bin/curl -L https://iterm2.com/shell_integration/install_shell_integration_and_utilities.sh | /bin/bash" vagrant',
    creates     => '/home/vagrant/.iterm2_shell_integration.bash',
    cwd         => '/home/vagrant',
    environment => ['HOME=/home/vagrant'],
  }
}
