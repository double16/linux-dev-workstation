#
# Visual Studio Code IDE, plugins and tools
#
class private::vscode {
  $extension_path = '/home/vagrant/.vscode/extensions'
  $cache_path = '/tmp/vagrant-cache/vscode-extensions'

  # VS Live Share
  package { [
    'libunwind',
    'lttng-ust',
  ]:}

  file { [ '/home/vagrant/.vscode', $extension_path ]:
    ensure => directory,
    mode   => '0755',
    owner  => 'vagrant',
    group  => 'vagrant',
  }

  file { $cache_path:
    ensure => directory,
    mode   => '0755',
    owner  => 'vagrant',
    group  => 'vagrant',
  }

  define extension() {
    $extension_path = $private::vscode::extension_path
    $cache_path = $private::vscode::cache_path
    $cache_file = "${cache_path}/${title}.tar.gz"

    unless $title in $::facts['vscodeextensions'] {
      exec { "vscode extension restore cache for ${title}":
        command => "/usr/bin/tar xzf \"${cache_file}\" -C \"${extension_path}\"",
        onlyif  => "/usr/bin/find \"${cache_file}\" -mtime -30 | grep -q .",
        require => File[$extension_path],
      }
      ->exec { "vscode extension ${title}":
        command => "/usr/bin/code --install-extension ${title}",
        user    => 'vagrant',
        timeout => 1200,
        unless  => "/usr/bin/find \"${extension_path}\" -maxdepth 1 -iname \"${title}-*\" | grep -q .",
        require => Package['code'],
        notify  => Exec["vscode extension save cache for ${title}"],
      }
      ~>exec { "vscode extension save cache for ${title}":
        command     => "/bin/rm -f \"${cache_file}\" ; /bin/ls \"${extension_path}\" | grep -iF \"${title}-\" | xargs -r /usr/bin/tar czf \"${cache_file}\" -C \"${extension_path}\"",
        refreshonly => true,
        onlyif      => '/usr/bin/mountpoint /tmp/vagrant-cache',
      }
    }
  }

  yum::gpgkey { '/etc/pki/rpm-gpg/RPM-GPG-KEY-microsoft.com':
    ensure => present,
    source => 'https://packages.microsoft.com/keys/microsoft.asc',
  }
  ->yum::gpgkey { '/etc/pki/rpm-gpg/RPM-GPG-KEY-msopentech':
    ensure => present,
    source => 'https://packages.microsoft.com/keys/msopentech.asc',
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
    'vscode-icons-team.vscode-icons',
    'formulahendry.code-runner',
    'redhat.java',
    'ms-vscode.go',
    'rebornix.Ruby',
    'ms-azuretools.vscode-docker',
    'humao.rest-client',
    'xabikos.ReactSnippets',
    'msjsdiag.vscode-react-native',
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
    'vscjava.vscode-java-debug',
    'vscjava.vscode-java-pack',
    'vscjava.vscode-java-test',
    'vscjava.vscode-maven',
    'vscjava.vscode-spring-boot-dashboard',
    'vscjava.vscode-spring-initializr',
    'dotjoshjohnson.xml',
    'eriklynd.json-tools',
    'christian-kohler.npm-intellisense',
    'esbenp.prettier-vscode',
    'kisstkondoros.vscode-codemetrics',
    'ms-kubernetes-tools.vscode-kubernetes-tools',
    'ms-vscode.node-debug2',
    'pivotal.vscode-boot-dev-pack',
    'pivotal.vscode-concourse',
    'pivotal.vscode-manifest-yaml',
    'pivotal.vscode-spring-boot',
    'redhat.vscode-yaml',
    'shan.code-settings-sync',
    'wix.vscode-import-cost',
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
