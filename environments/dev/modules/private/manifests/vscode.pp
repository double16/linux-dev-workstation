#
# Visual Studio Code IDE, plugins and tools
#
class private::vscode {
  $cache_path = '/tmp/vagrant-cache/vscode-extensions'
  $extension_path = '/home/vagrant/.vscode/extensions'

  # VS Live Share
  package { [
    'libunwind',
    'lttng-ust',
  ]:}

  file { $cache_path:
    ensure => directory,
    mode   => '0777',
    owner  => 'vagrant',
    group  => 'vagrant',
  }
  file { [ '/home/vagrant/.vscode', $extension_path ]:
    ensure => directory,
    mode   => '0755',
    owner  => 'vagrant',
    group  => 'vagrant',
  }

  exec { 'vscode expire cache':
    command => "/usr/bin/find ${cache_path} -maxdepth 1 -mtime +30 | xargs -r rm -rf",
    require => [ File[$cache_path] ],
  }
  ->exec { 'vscode install from cache':
    command => "/usr/bin/rsync -r --size-only --chown vagrant:vagrant ${cache_path}/ ${extension_path}/",
    timeout => 1800,
    require => [ File[$cache_path], File[$extension_path], Package['rsync'] ],
  }
  ->Private::Vscode::Extension<| |>

  Private::Vscode::Extension<| |>
  ~>exec { 'vscode populate cache':
    command     => "/usr/bin/rsync -r --size-only --delete ${extension_path}/ ${cache_path}/",
    timeout     => 1800,
    refreshonly => true,
    require     => [ File[$cache_path], File[$extension_path], Package['rsync'] ],
  }

  define extension() {
    exec { "vscode extension ${title}":
      command => "/usr/bin/code --install-extension ${title}",
      unless  => "/usr/bin/code --list-extensions | grep -q ${title}",
      user    => 'vagrant',
      require => Package['code'],
    }
  }

  yum::gpgkey { '/etc/pki/rpm-gpg/RPM-GPG-KEY-microsoft.com':
    ensure => present,
    source => 'https://packages.microsoft.com/keys/microsoft.asc',
  }
  ->file { '/etc/yum.repos.d/vscode.repo':
    mode    => '0644',
    owner   => 0,
    group   => 'root',
    content => '[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
',
  }

  Yum::Group<| title == 'X Window System' |>
  ->package { 'mesa-libGL': }
  ->package { 'code':
    require => File['/etc/yum.repos.d/vscode.repo'],
  }

  package { [ 'pylint', 'autopep8' ]:
    provider => 'pip',
  }

  $global_color_scheme = pick($::theme, lookup('theme::default')) ? {
    /light/ => 'Solarized Light',
    /dark/  => 'Solarized Dark',
    /none/  => '',
    default => undef,
  }
  $init_global_color_scheme = empty($global_color_scheme) ? {
    true    => '',
    default => "\"workbench.colorTheme\": \"${global_color_scheme}\"",
  }

  private::vscode::extension { [
    'Braver.vscode-solarized',
    'nodesource.vscode-for-node-js-development-pack',
    'eamodio.gitlens',
    'msjsdiag.debugger-for-chrome',
    'ms-python.python',
    'robertohuertasm.vscode-icons',
    'formulahendry.code-runner',
    'redhat.java',
    'ms-vscode.Go',
    'rebornix.Ruby',
    'PeterJausovec.vscode-docker',
    'humao.rest-client',
    'xabikos.ReactSnippets',
    'vsmobile.vscode-react-native',
    'naco-siren.gradle-language',
    'yzhang.markdown-all-in-one',
    'dbaeumer.vscode-eslint',
    'eg2.tslint',
    'ecmel.vscode-html-css',
    'octref.vetur',
    'formulahendry.auto-close-tag',
    'rbbit.typescript-hero',
    'jpogran.puppet-vscode',
    'mrmlnc.vscode-json5',
    'wholroyd.HCL',
    'mauve.terraform',
    'mindginative.terraform-snippets',
    'stayfool.vscode-asciidoc',
    'vscjava.vscode-java-pack',
  ]: }
  ->file { '/home/vagrant/.config/Code':
    ensure => directory,
    owner  => 'vagrant',
    group  => 'vagrant',
    mode   => '0700',
  }
  ->file { '/home/vagrant/.config/Code/User':
    ensure => directory,
    owner  => 'vagrant',
    group  => 'vagrant',
    mode   => '0775',
  }
  ->file { '/home/vagrant/.config/Code/User/settings.json':
    ensure  => file,
    replace => false,
    owner   => 'vagrant',
    group   => 'vagrant',
    mode    => '0664',
    content => "
{
    \"workbench.iconTheme\": \"vscode-icons\",
    \"vsicons.dontShowNewVersionMessage\": true,
    ${init_global_color_scheme},
    \"git.confirmSync\": false,
    \"gradle.useCommand\": \"./gradlew\",
    \"editor.wordWrap\": \"on\",
    \"editor.formatOnPaste\": true
}
",
  }

  unless empty($::theme) {
    if empty($global_color_scheme) {
      $global_color_scheme_changes = [
          "rm dict/entry[. = \"workbench.colorTheme\"]",
      ]
    } else {
      $global_color_scheme_changes = [
          "set dict/entry[. = \"workbench.colorTheme\"]/string \"${global_color_scheme}\"",
      ]
    }
    augeas { 'vscode theme':
      incl    => '/home/vagrant/.config/Code/User/settings.json',
      lens    => "Json.lns",
      context => "/files/home/vagrant/.config/Code/User/settings.json",
      changes => $global_color_scheme_changes,
      require => File['/home/vagrant/.config/Code/User/settings.json'],
    }
  }
}
