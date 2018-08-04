class private::my_vim {
  $global_color_scheme = pick($::theme, lookup('theme::default'))

  yum::gpgkey { '/etc/pki/rpm-gpg/RPM-GPG-KEY-mcepl-vim8-epel7':
    ensure  => present,
    content => '-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v2

mQENBFfac9gBCAC8K6Ps7dW/wdbWLp99NsXi4MuZ57ktabj2dzaDfzArr47/yt81
z8Yriw9n9ZjTo9aZAtyMhGKAi2Eo4j9IKoGMy8xbbHRAUUdL13gJ4GfrdRqGyVF/
+cLseLwk9mam6hPVgx2BAcaA/6jaMM6wcIBrVE57l+V67QbMccUt9EOF2RXjiulL
oF1ylqkGhfhvZtw+pCCtxIwbfh21FlXBAmr+yXG0JRYB4ezEkqEcr+yFMNEKt+vl
LNEoCh3psgDgDZvs4V5PVyivIaVR4XEcpkbRSiO4iEKZREeZ4xsaygsoPkh1lrWp
k+BGB79Y4tvG2FlP7sklPZrFf9+7k3sAJguRABEBAAG0NG1jZXBsX3ZpbTggKE5v
bmUpIDxtY2VwbCN2aW04QGNvcHIuZmVkb3JhaG9zdGVkLm9yZz6JAT0EEwEIACcF
Alfac9gCGy8FCQlmAYAFCwkIBwIGFQgJCgsCBBYCAwECHgECF4AACgkQPtoan0Hw
2KiwGQgAtarc4zvIoolNp4QbRxG+dH/n9Cq+/wh1Fwh6q4/zTFDWllDc2KPe+0d+
UpXjeF/rb6AlDgY47n7rMzr1TSq3Vn+rZBlKOLJIS/vdDNVgQJxB/xwpJ1UQaxHG
nhr6hxI3NDtl1Rpre2R8020VGBfnuKbbtpEyU/jfCx7XKT/jjydzovLBh2PDykvu
QkyKHtsuhgROJdj/cDi1e7g0JWDhm4r+79OeT/q7Azf4AqUzfeEwOVpS0FvqOdK0
uZqdSXy8bHM0xVSJSC0qhr9HJi9r13Eb+1NCKNzZqe/FqOUTWM5e5OHqb3As6Cjy
EM2mrdKYTJ+wFGIm+bpFqzRpoQbi8g==
=gdmo
-----END PGP PUBLIC KEY BLOCK-----
',
  }
  ->remote_file {'/etc/yum.repos.d/mcepl-vim8-epel-7.repo':
    ensure => present,
    source => 'https://copr.fedorainfracloud.org/coprs/mcepl/vim8/repo/epel-7/mcepl-vim8-epel-7.repo',
    mode   => '0644',
    owner  => 0,
    group  => 0,
  }
  ->Package<| |>
  Remote_file['/etc/yum.repos.d/mcepl-vim8-epel-7.repo']
  ->Yum::Group<| |>

  # In some cases replacing vim-minimal will remove 'sudo', but instaling vim-enhanced on top of vim-minimal is allowed
  exec { 'yum install -y vim-enhanced || yum replace -y vim-minimal --replace-with=vim-enhanced':
    unless  => 'yum --cacheonly list installed vim-enhanced | grep -q 8.0',
    path    => '/bin:/sbin:/usr/bin:/usr/sbin',
    require => [ Yum::Plugin['replace'], Remote_file['/etc/yum.repos.d/mcepl-vim8-epel-7.repo'] ],
  }
  ->class { '::vim':
    autoupgrade    => true,
    set_as_default => true,
    opt_syntax     => true,
    opt_misc       => ['number'],
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

  package { ['cmake','python-devel']: }
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
    require => [ Package['go'] ],
  }
  Nodenv::Package<| |>
  -> Private::My_vim::Plugin['valloric/youcompleteme']
  Git::Config<| |>
  -> Private::My_vim::Plugin['valloric/youcompleteme']
}
