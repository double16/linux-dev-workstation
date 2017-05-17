class kitematic
{
  package { ['rpmrebuild','zsh','libnotify']: }
  ->archive { 'Kitematic-0.17.0':
    ensure           => present,
    url              => 'https://github.com/docker/kitematic/releases/download/v0.17.0/Kitematic-0.17.0-Ubuntu.zip',
    target           => '/opt',
    follow_redirects => true,
    extension        => 'zip',
    checksum         => false,
    #checksum_type => 'sha256',
  }
  ->exec { 'Kitematic rpm':
    command => '/usr/bin/alien -r -k /opt/Kitematic_0.17.0_amd64.deb',
    creates => '/opt/kitematic-0.17.0-1.x86_64.rpm',
    cwd     => '/opt',
    require => Package['alien'],
  }
  ->exec { 'Kitematic rpm fixes':
    command => '/usr/bin/rpmrebuild --batch --install --change-spec-files=\'grep -v "\\"/\\"\\|\\"/usr\\"\\|\\"/usr/bin\\"\\|\\"/usr/share\\"\\|\\"/usr/share/applications\\"\\|\\"/usr/share/doc\\"\\|\\"/usr/share/pixmaps\\""\' -p /opt/kitematic-0.17.0-1.x86_64.rpm',
    creates => '/usr/bin/kitematic',
    require => Package['rpmrebuild'],
  }
}

