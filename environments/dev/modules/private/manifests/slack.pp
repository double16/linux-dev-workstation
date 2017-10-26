class private::slack {
  package { ['libappindicator', 'libsecret']: }
  remote_file { '/tmp/vagrant-cache/slack-2.8.2-0.1.fc21.x86_64.rpm':
    ensure        => present,
    source        => 'https://downloads.slack-edge.com/linux_releases/slack-2.8.2-0.1.fc21.x86_64.rpm',
    checksum      => '6fc2c41e650e8b29904bc832a499bb3ac2480d216f2003d4c9581ee222e7356c',
    checksum_type => 'sha256',
    require       => File['/tmp/vagrant-cache'],
  }
  ->package { 'slack':
    provider => rpm,
    source   => '/tmp/vagrant-cache/slack-2.8.2-0.1.fc21.x86_64.rpm',
    require  => Package['libappindicator'],
  }
}

