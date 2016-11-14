class my_vim {
  class { 'vim':
    autoupgrade    => true,
    opt_syntax     => true,
    opt_bg_shading => 'light',
    opt_misc       => ['number'],
  }
  package{ 'gvim': }

  vcsrepo { '/opt/xfce4-terminal-colors-solarized':
    ensure   => present,
    provider => git,
    source   => 'https://github.com/sgerrand/xfce4-terminal-colors-solarized',
  }->
  file { '/home/vagrant/.config':
    ensure => directory,
  }-> file { '/home/vagrant/.config/xfce4':
    ensure => directory,
  }-> file { '/home/vagrant/.config/xfce4/terminal':
    ensure => directory,
  }-> file { '/home/vagrant/.config/xfce4/terminal/terminalrc':
    ensure => file,
    owner  => 'vagrant',
    group  => 'vagrant',
    mode   => '0644',
    source => '/opt/xfce4-terminal-colors-solarized/light/terminalrc',
  }

  define plugin() {
    $plugin_name = split($title, '/')[1]

    vim::plugin { $plugin_name:
      user => 'vagrant',
      url  => "https://github.com/${title}.git",
    }
  }

  vim::pathogen { 'vagrant': }
  my_vim::plugin { [
     'scrooloose/syntastic',
     'altercation/vim-colors-solarized',
     'rodjek/vim-puppet',
     'maksimr/vim-jsbeautify',
     'elzr/vim-json',
     'bronson/vim-trailing-whitespace',
     'ervandew/matchem',
     'jtratner/vim-flavored-markdown',
  ]:
  }

  vim::config { 'colorscheme':
    user    => 'vagrant',
    content => 'colorscheme solarized',
  }
}
