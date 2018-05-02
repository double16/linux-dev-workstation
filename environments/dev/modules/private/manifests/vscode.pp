#
# Visual Studio Code IDE, plugins and tools
#
class private::vscode {

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

  private::vscode::extension { [
    'Braver.vscode-solarized',
    'nodesource.vscode-for-node-js-development-pack',
    'eamodio.gitlens',
    'msjsdiag.debugger-for-chrome',
    'ms-python.python',
    'robertohuertasm.vscode-icons',
    'formulahendry.code-runner',
    'redhat.java',
    'lukehoban.Go',
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
    content => '
{
    "workbench.iconTheme": "vscode-icons",
    "workbench.colorTheme": "Solarized Light",
    "git.confirmSync": false,
    "editor.wordWrap": "on",
    "editor.formatOnPaste": true
}
',
  }
}

