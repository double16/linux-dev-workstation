class private::slack {
  package { ['libappindicator', 'libsecret']: }
  ->archive { '/tmp/vagrant-cache/slack-3.0.5-0.1.fc21.x86_64.rpm':
    ensure          => present,
    source          => 'https://downloads.slack-edge.com/linux_releases/slack-3.0.5-0.1.fc21.x86_64.rpm',
    extract         => true,
    extract_path    => '/tmp',
    extract_command => 'rpm -ivh %s',
    creates         => '/usr/bin/slack',
    checksum        => '2733a1ea85275409fb55657b2fc032f49e91973fc8a90ac3a105940bb16579e4',
    checksum_type   => 'sha256',
    require         => File['/tmp/vagrant-cache'],
  }
}
