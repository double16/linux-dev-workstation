class private::my_vim {
  $global_color_scheme = pick($::theme, lookup('theme::default'))
  $vim_config = lookup('vim', Hash)
  $version = $vim_config['version']

  class { '::vim':
    autoupgrade    => false,
    set_as_default => true,
    package        => 'vim-minimal', # we compile the full VIM from source
    opt_syntax     => true,
    opt_misc       => ['number'],
  }

  ensure_packages(['gcc-c++', 'ncurses-devel', 'python-devel', 'python-requests'])

  archive { "/tmp/vagrant-cache/vim-${version}.tar.gz":
    source       => "https://github.com/vim/vim/archive/v${version}.tar.gz",
    extract_path => '/usr/src',
    extract      => true,
    cleanup      => false,
    creates      => "/usr/src/vim-${version}",
    require      => File['/tmp/vagrant-cache'],
  }
  ->exec { "make configure vim ${version}":
    path    => ['/bin','/sbin','/usr/bin','/usr/sbin','/usr/local/bin'],
    cwd     => "/usr/src/vim-${version}",
    command => 'make configure',
    creates => "/usr/src/vim-${version}/configure",
    require => [ Package['gcc-c++'], Package['ncurses-devel'], Package['python-devel'] ],
  }
  ->exec { "configure vim ${version}":
    path    => ['/bin','/sbin','/usr/bin','/usr/sbin','/usr/local/bin'],
    cwd     => "/usr/src/vim-${version}",
    command => "/usr/src/vim-${version}/configure --prefix=/usr --enable-cscope --enable-gui=no --enable-multibyte --enable-pythoninterp --enable-rubyinterp --with-features=huge --with-python-config-dir=/usr/lib/python2.7/config --with-tlib=ncurses --without-x",
    unless  => "grep -qF 'S[\"prefix\"]=\"/usr\"' /usr/src/vim-${version}/config.status",
  }
  ->exec { "build vim ${version}":
    path      => ['/bin','/sbin','/usr/bin','/usr/sbin','/usr/local/bin'],
    cwd       => "/usr/src/vim-${version}",
    command   => 'make',
    creates   => "/usr/src/vim-${version}/vim",
    timeout   => 900,
    subscribe => Exec["configure vim ${version}"],
  }
  ->exec { "install vim ${version}":
    path      => ['/bin','/sbin','/usr/bin','/usr/sbin','/usr/local/bin'],
    cwd       => "/usr/src/vim-${version}",
    command   => 'make install',
    unless    => "/usr/bin/test -f /usr/bin/vim && /usr/bin/vim --version | grep -qF ${version}",
    subscribe => Exec["build vim ${version}"],
    require   => [ Package['vim-minimal'] ],
  }
  ->package{ 'gvim': }
  
  define plugin() {
    $plugin_name = split($title, '/')[1]

    vim::plugin { $plugin_name:
      user => 'vagrant',
      url  => "https://github.com/${title}.git",
    }
  }

  vim::pathogen { 'vagrant': }
  private::my_vim::plugin { [
    'scrooloose/syntastic',
    'scrooloose/nerdtree',
    'Xuyuanp/nerdtree-git-plugin',
    'altercation/vim-colors-solarized',
    'rodjek/vim-puppet',
    'maksimr/vim-jsbeautify',
    'elzr/vim-json',
    'bronson/vim-trailing-whitespace',
    'ervandew/matchem',
    'jtratner/vim-flavored-markdown',
    'nathanaelkane/vim-indent-guides',
    'tpope/vim-fugitive',
    'bling/vim-airline',
    'fatih/vim-go',
    'vim-ruby/vim-ruby',
    'tpope/vim-endwise',
    'othree/html5.vim',
    'junegunn/gv.vim',
    'tpope/vim-commentary',
    'ctrlpvim/ctrlp.vim',
    'ekalinin/dockerfile.vim',
    'editorconfig/editorconfig-vim',
  ]:
  }


  unless empty($global_color_scheme) or $global_color_scheme == 'none' {
    ['vagrant', 'root'].each |$user| {
      vim::config { "solarized_termtrans for ${user}":
        user    => $user,
        content => 'let g:solarized_termtrans=1',
        order   => '02',
      }
      vim::config { "solarized_termcolors ${user}":
        user    => $user,
        content => 'let g:solarized_termcolors=256',
        order   => '03',
      }
      vim::config { "background ${user}":
        user    => $user,
        content => "set background=${global_color_scheme}",
        order   => '04',
      }
      vim::config { "colorscheme ${user}":
        user    => $user,
        content => 'colorscheme solarized',
        order   => '04',
      }
    }
  }

  define beautify($filetype = $title, $allfn, $rangefn) {
    vim::config { "beautify ${filetype}":
      user    => 'vagrant',
      content => "autocmd FileType ${filetype} noremap <buffer>  <c-f> :call ${allfn}()<cr>",
    }
    vim::config { "beautify ${filetype} for range":
      user    => 'vagrant',
      content => "autocmd FileType ${filetype} vnoremap <buffer>  <c-f> :call ${rangefn}()<cr>",
    }
  }
  private::my_vim::beautify { 'javascript':
    allfn   => 'JsBeautify',
    rangefn => 'RangeJsBeautify',
  }
  private::my_vim::beautify { 'jsx':
    allfn   => 'JsxBeautify',
    rangefn => 'RangeJsxBeautify',
  }
  private::my_vim::beautify { 'html':
    allfn   => 'HtmlBeautify',
    rangefn => 'RangeHtmlBeautify',
  }
  private::my_vim::beautify { 'css':
    allfn   => 'CSSBeautify',
    rangefn => 'RangeCSSBeautify',
  }

  package { 'ctags': }
  ->private::my_vim::plugin { 'majutsushi/tagbar': }
  ->vim::config { 'tagbartoggle':
    user    => 'vagrant',
    content => 'nmap <F8> :TagbarToggle<cr>',
  }

  # https://unix.stackexchange.com/questions/196098/copy-paste-in-xfce4-terminal-adds-0-and-1
  vim::config { 'disable bracketed paste mode':
    user    => 'vagrant',
    content => 'set t_BE=',
  }

  package { ['cmake']: }
  -> private::my_vim::plugin { 'valloric/youcompleteme': }
  -> exec { 'youcompleteme submodule':
    path    => ['/bin','/sbin','/usr/bin','/usr/sbin','/usr/local/bin','/usr/local/sbin'],
    command => 'git submodule update --init --recursive',
    cwd     => '/home/vagrant/.vim/bundle/youcompleteme',
    creates => '/home/vagrant/.vim/bundle/youcompleteme/third_party/ycmd/build.py',
    user    => 'vagrant',
    timeout => 900,
  }
  -> exec { 'compile youcompleteme':
    path    => ['/bin','/sbin','/usr/bin','/usr/sbin','/usr/local/bin','/usr/local/sbin','/opt/nodenv/shims'],
    command => '/home/vagrant/.vim/bundle/youcompleteme/install.py --gocode-completer --tern-completer',
    creates => '/home/vagrant/.vim/bundle/youcompleteme/third_party/ycmd/ycm_core.so',
    user    => 'vagrant',
    timeout => 0,
    require => [ Package['go'], Package['python-devel'], Package['python-requests'] ],
  }
  Nodenv::Package<| |>
  -> Private::My_vim::Plugin['valloric/youcompleteme']
  Git::Config<| |>
  -> Private::My_vim::Plugin['valloric/youcompleteme']
}
