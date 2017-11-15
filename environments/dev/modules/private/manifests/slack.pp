class private::slack {
  package { ['libappindicator', 'libsecret']: }
  ->archive { '/tmp/vagrant-cache/slack-2.8.2-0.1.fc21.x86_64.rpm':
    ensure          => present,
    source          => 'https://downloads.slack-edge.com/linux_releases/slack-2.8.2-0.1.fc21.x86_64.rpm',
    extract         => true,
    extract_path    => '/tmp',
    extract_command => 'rpm -ivh %s',
    creates         => '/usr/bin/slack',
    checksum        => '6fc2c41e650e8b29904bc832a499bb3ac2480d216f2003d4c9581ee222e7356c',
    checksum_type   => 'sha256',
    require         => File['/tmp/vagrant-cache'],
  }
}

