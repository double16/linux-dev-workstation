#
# Installs iTerm2 integration
#
class private::iterm2 {
  $iterm2_dir = '/usr/local/lib/iterm2'

  # from https://iterm2.com/shell_integration/install_shell_integration.sh, UTILITIES
  $iterm2_commands = [ 'imgcat', 'imgls', 'it2api', 'it2attention', 'it2check', 'it2copy', 'it2dl', 'it2getvar', 'it2git', 'it2setcolor', 'it2setkeylabel', 'it2ul', 'it2universion' ]

  package { [ 'php', 'coreutils' ]: }

  file { $iterm2_dir:
    ensure => directory,
    owner  => 0,
    group  => 'root',
    mode   => '0755',
  }

  private::cached_remote_file { "${iterm2_dir}/iterm2_shell_integration.bash":
    cache_name => "iterm2_shell_integration.bash",
    source     => "https://iterm2.com/shell_integration/bash",
    owner      => 0,
    group      => 'root',
    mode       => '0755',
  }

  private::cached_remote_file { "${iterm2_dir}/iterm2_shell_integration.zsh":
    cache_name => "iterm2_shell_integration.zsh",
    source     => "https://iterm2.com/shell_integration/zsh",
    owner      => 0,
    group      => 'root',
    mode       => '0755',
  }

  $iterm2_commands.each |$util| {
    private::cached_remote_file { "${iterm2_dir}/${util}":
      cache_name => "iterm2_${util}",
      source     => "https://iterm2.com/utilities/${util}",
      owner      => 0,
      group      => 'root',
      mode       => '0755',
    }
  }
 
  file { '/etc/profile.d/iterm2.sh':
    ensure => file,
    owner  => 0,
    group  => 'root',
    mode   => '0644',
    content => "
case \"\$SHELL\" in
  */zsh)
    test -e \"/usr/local/lib/iterm2_shell_integration.zsh\" && source \"/usr/local/lib/iterm2_shell_integration.zsh\"
  ;;
  */bash|*/sh)
    test -e \"/usr/local/lib/iterm2_shell_integration.bash\" && source \"/usr/local/lib/iterm2_shell_integration.bash\"
  ;;
esac

find \"${iterm2_dir}\" -type f -executable -not -name \"iterm2_shell_integration.*\" -printf \"%f\\n\" | while read U; do
  alias \$U=\"${iterm2_dir}/\$U\"
done
",
  }
}
