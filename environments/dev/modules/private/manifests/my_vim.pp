class private::my_vim {
  $global_color_scheme = pick($::theme, lookup('theme::default'))
  $plugin_path = '/home/vagrant/.vim/bundle'
  $plugin_cache_path = '/tmp/vagrant-cache/vim-plugins'

  $vim_plugins = [
    'scrooloose/syntastic',
    'scrooloose/nerdtree',
    'Xuyuanp/nerdtree-git-plugin',
    'lifepillar/vim-solarized8',
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
  ]

  class { '::vim':
    autoupgrade    => false,
    set_as_default => true,
    package        => 'vim',
    opt_syntax     => true,
    opt_misc       => ['number'],
  }

  file { '/usr/local/bin/vim-version.sh':
    ensure  => file,
    mode    => '0755',
    content => '#!/bin/bash

test -f /usr/bin/vim || exit 1

S="$(/usr/bin/vim --version | head -n 2)"
MAJOR_MINOR="$(echo $S | grep -oE \'IMproved ([0-8.]+)\' | cut -d \' \' -f 2)"
PATCHES="000$(echo $S | grep -oE \'patches: [0-9]+-[0-9]+\'| cut -d \'-\' -f 2)"
PATCHES="${PATCHES: -4}"

echo "${MAJOR_MINOR}.${PATCHES}"
',
  }


  file { '/etc/profile.d/editor.sh':
    mode    => '0755',
    content => 'export VISUAL="vim"
export EDITOR="vim"',
  }
  ->package{ 'gvim': }

  file { $plugin_cache_path:
    ensure => directory,
    mode   => '0755',
    owner  => 'vagrant',
    group  => 'vagrant',
  }

  define plugin() {
    $plugin_name = split($title, '/')[1]
    $plugin_path = $private::my_vim::plugin_path
    $plugin_cache_path = $private::my_vim::plugin_cache_path

    vim::plugin { $plugin_name:
      user => 'vagrant',
      url  => "https://github.com/${title}.git",
    }

    $cache_file = "${plugin_cache_path}/${plugin_name}.tgz"
    exec { "vim plugin restore cache for ${title}":
      command => "/usr/bin/tar xzf \"${cache_file}\" -C \"${plugin_path}\"",
      onlyif  => "/usr/bin/find \"${cache_file}\" -mtime -30 | grep -q .",
      creates => "${plugin_path}/${plugin_name}",
      require => File[$plugin_path],
    }
    ->Exec<| title == "vagrant-${plugin_name}" |>
    ~>exec { "vim plugin save cache for ${title}":
      command     => "/bin/rm -f \"${cache_file}\" ; /bin/ls \"${plugin_path}\" | grep -iF \"${plugin_name}\" | xargs -r /usr/bin/tar czf \"${cache_file}\" -C \"${plugin_path}\"",
      refreshonly => true,
      require     => File[$plugin_cache_path],
      onlyif      => '/usr/bin/mountpoint /tmp/vagrant-cache',
    }
  }

  vim::pathogen { 'vagrant': }
  private::my_vim::plugin { $vim_plugins: }

  unless empty($global_color_scheme) or $global_color_scheme == 'none' {
    ['vagrant'].each |$user| {
      if $user == 'root' {
        $home = '/root'
      } else {
        $home = "/home/${user}"
      }
      vim::config { "background ${user}":
        user    => $user,
        content => "set background=${global_color_scheme}",
        order   => '04',
      }
      vim::config { "colorscheme ${user}":
        user    => $user,
        content => 'colorscheme solarized8',
        order   => '04',
      }
      file { "${home}/.vim/colors":
        ensure => directory,
        owner  => $user,
        group  => $user,
        mode   => '0755',
      }
      Private::My_vim::Plugin<| |>
      ->file { "${home}/.vim/colors/solarized8.vim":
        ensure  => link,
        target  => "${home}/.vim/bundle/vim-solarized8/colors/solarized8.vim",
        owner   => $user,
        group   => $user,
        require => File["${home}/.vim/colors"],
      }
      ->file { "${home}/.vim/colors/solarized8_flat.vim":
        ensure  => link,
        target  => "${home}/.vim/bundle/vim-solarized8/colors/solarized8_flat.vim",
        owner   => $user,
        group   => $user,
        require => File["${home}/.vim/colors"],
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

  vim::config { 'filetype':
    user    => 'vagrant',
    content => 'filetype on',
  }

  vim::config { 'filetype indent':
    user    => 'vagrant',
    content => 'filetype plugin indent on',
  }

  $ycm_cache_file = "${plugin_cache_path}/youcompleteme-built.tgz"
  package { ['cmake', 'python-devel', 'python-requests']: }
  exec { 'restore cache for youcompleteme':
    command => "/usr/bin/tar xzf \"${ycm_cache_file}\" -C \"${plugin_path}\"",
    onlyif  => "/usr/bin/find \"${ycm_cache_file}\" -mtime -30 | grep -q .",
    creates => "${plugin_path}/youcompleteme",
    require => File[$plugin_path],
  }
  -> private::my_vim::plugin { 'valloric/youcompleteme': }
  -> exec { 'youcompleteme submodule':
    path    => ['/bin','/sbin','/usr/bin','/usr/sbin','/usr/local/bin','/usr/local/sbin'],
    command => 'git submodule update --init --recursive',
    cwd     => '/home/vagrant/.vim/bundle/youcompleteme',
    creates => '/home/vagrant/.vim/bundle/youcompleteme/third_party/ycmd/build.py',
    user    => 'vagrant',
    timeout => 1800,
  }
  -> exec { 'compile youcompleteme':
    path      => ['/bin','/sbin','/usr/bin','/usr/sbin','/usr/local/bin','/usr/local/sbin','/opt/nodenv/shims'],
    command   => '/bin/su -l -c "/usr/bin/go env GOCACHE | grep home/vagrant && /home/vagrant/.vim/bundle/youcompleteme/install.py --gocode-completer --tern-completer" vagrant',
    creates   => '/home/vagrant/.vim/bundle/youcompleteme/third_party/ycmd/ycm_core.so',
    user      => 0,
    timeout   => 0,
    require   => [ Package['go'], Package['python-devel'], Package['python-requests'] ],
    logoutput => true,
  }
  ~>exec { 'save cache for youcompleteme':
    command     => "/bin/rm -f \"${ycm_cache_file}\" ; /bin/ls \"${plugin_path}\" | grep -iF \"youcompleteme\" | xargs -r /usr/bin/tar czf \"${ycm_cache_file}\" -C \"${plugin_path}\"",
    refreshonly => true,
    require     => File[$plugin_cache_path],
    onlyif      => '/usr/bin/mountpoint /tmp/vagrant-cache',
  }

  Nodenv::Package<| |>
  -> Private::My_vim::Plugin['valloric/youcompleteme']
  Git::Config<| |>
  -> Private::My_vim::Plugin['valloric/youcompleteme']
}
