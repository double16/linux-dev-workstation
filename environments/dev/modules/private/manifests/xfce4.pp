class private::xfce4 {
  $global_color_scheme = pick($::theme, lookup('theme::default'))

  file { '/home/vagrant/.config/xfce4':
    ensure  => directory,
    recurse => remote,
    replace => false,
    owner   => 'vagrant',
    group   => 'vagrant',
    source  => 'puppet:///modules/private/dotconfig/xfce4',
  }

  vcsrepo { '/opt/xfce4-terminal-colors-solarized':
    ensure   => present,
    provider => git,
    source   => 'https://github.com/sgerrand/xfce4-terminal-colors-solarized',
  }
  ->file { '/home/vagrant/.config/xfce4/terminal':
    ensure => directory,
    owner  => 'vagrant',
    group  => 'vagrant',
    mode   => '0755',
  }

  if $global_color_scheme == 'none' {
    file { '/home/vagrant/.config/xfce4/terminal/terminalrc':
      ensure => absent,
    }
  } elsif !empty($global_color_scheme) {
    file { '/home/vagrant/.config/xfce4/terminal/terminalrc':
      ensure  => file,
      replace => $::theme != undef,
      owner   => 'vagrant',
      group   => 'vagrant',
      mode    => '0644',
      source  => "/opt/xfce4-terminal-colors-solarized/${global_color_scheme}/terminalrc",
    }
  }

  $xfce4_theme = $global_color_scheme ? {
    /light/ => 'Adwaita',
    /dark/  => 'Adwaita-dark',
    /none/  => '',
    default => undef,
  }
  unless empty($::theme) or empty($xfce4_theme) {
    augeas { 'xfce4 theme':
      incl    => '/home/vagrant/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml',
      lens    => 'Xml.lns',
      context => '/files//home/vagrant/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml',
      changes => [
          "set channel[#attribute/name=\"xsettings\"]/property[#attribute/name=\"Net\"]/property[#attribute/name=\"ThemeName\"]/#attribute/value \"${xfce4_theme}\"",
      ],
      require => File['/home/vagrant/.config/xfce4'],
    }
    ~>notify { 'xfce4_theme_message': 
      message => 'Window theme changed, run `vagrant reload` to apply',
    }
  }
}
