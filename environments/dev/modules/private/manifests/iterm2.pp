#
# Installs iTerm2 integration
#
class private::iterm2 {
  package { [ 'php', 'coreutils' ]: }

  private::cached_remote_file { '/usr/local/lib/iterm2_shell_integration.bash':
    cache_name => "iterm2_shell_integration.bash",
    source     => "https://iterm2.com/shell_integration/bash",
    owner      => 0,
    group      => 'root',
  }

  private::cached_remote_file { '/usr/local/lib/iterm2_shell_integration.zsh':
    cache_name => "iterm2_shell_integration.zsh",
    source     => "https://iterm2.com/shell_integration/zsh",
    owner      => 0,
    group      => 'root',
  }

  file { '/etc/profile.d/iterm2.sh':
    ensure => file,
    owner  => 0,
    group  => 'root',
    mode   => '0644',
    content => '
case "$SHELL" in
  */zsh)
    test -e "/usr/local/lib/iterm2_shell_integration.zsh" && source "/usr/local/lib/iterm2_shell_integration.zsh"
  ;;
  */bash|*/sh)
    test -e "/usr/local/lib/iterm2_shell_integration.bash" && source "/usr/local/lib/iterm2_shell_integration.bash"
  ;;

esac
',
  }
}
