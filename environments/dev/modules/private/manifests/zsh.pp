# zsh and friends
class private::zsh {
  package { ['zsh', 'zsh-lovers', 'zsh-syntax-highlighting', 'powerline-fonts']:
  }

  $zsh_theme = pick(lookup('zsh')['theme'], 'agnoster')
  $zsh_plugins = pick(lookup('zsh')['plugins'], 'git')

  [ 'vagrant', 'root' ].each |$user| {

    $homedir = $user ? {
      'root'  => '/root',
      default => "/home/${user}",
    }
    $omz_home = "${homedir}/.oh-my-zsh"

    vcsrepo { $omz_home:
      ensure   => present,
      provider => git,
      source   => 'https://github.com/robbyrussell/oh-my-zsh.git',
      user     => $user,
      require  => [ Package['zsh'], Package['powerline-fonts'] ],
    }
    ->exec { "${user} zshrc":
      command => "/usr/bin/cp ${omz_home}/templates/zshrc.zsh-template ${homedir}/.zshrc",
      unless  => "/usr/bin/grep -q ZSH_THEME ${homedir}/.zshrc",
      user    => $user,
      # sdkman will update .zshrc if present
      before  => Class['::sdkman'],
    }
    ->file_line { "${user} omz home":
      path  => "${homedir}/.zshrc",
      line  => "export ZSH=${omz_home}",
      match => '^export ZSH=',
    }
    ->file_line { "${user} zsh theme":
      path  => "${homedir}/.zshrc",
      line  => "ZSH_THEME=\"${zsh_theme}\"",
      match => '^ZSH_THEME=',
    }
    ->file_line { "${user} omz plugins":
      path  => "${homedir}/.zshrc",
      line  => "plugins=(${zsh_plugins})",
      match => '^plugins=',
    }
  }
}
