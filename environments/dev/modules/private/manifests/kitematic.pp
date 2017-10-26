class private::kitematic
{
  package { ['rpmrebuild','zsh','libnotify']: }
  ->archive { '/tmp/vagrant-cache/Kitematic-0.17.1.zip':
    ensure        => present,
    source        => 'https://github.com/docker/kitematic/releases/download/v0.17.1/Kitematic-0.17.1-Ubuntu.zip',
    extract_path  => '/opt',
    extract       => true,
    checksum      => '247c3fe68f3503a715448ee3b4742c125bf99ee643d3206b2b55d5c93a9af5fc',
    checksum_type => 'sha256',
    creates       => '/opt/Kitematic_0.17.1_amd64.deb',
    require       => File['/tmp/vagrant-cache'],
  }
  ->exec { 'Kitematic rpm':
    command => '/usr/bin/alien -r -k /opt/Kitematic_0.17.1_amd64.deb',
    creates => '/opt/kitematic-0.17.1-1.x86_64.rpm',
    cwd     => '/opt',
    timeout => 0,
    require => Package['alien'],
  }
  ->exec { 'Kitematic rpm fixes':
    command => '/usr/bin/rpmrebuild --batch --install --change-spec-files=\'grep -v "\\"/\\"\\|\\"/usr\\"\\|\\"/usr/bin\\"\\|\\"/usr/share\\"\\|\\"/usr/share/applications\\"\\|\\"/usr/share/doc\\"\\|\\"/usr/share/pixmaps\\""\' -p /opt/kitematic-0.17.1-1.x86_64.rpm',
    creates => '/usr/bin/kitematic',
    timeout => 0,
    require => Package['rpmrebuild'],
  }
}

