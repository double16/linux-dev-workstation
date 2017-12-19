class private::slack {
  package { ['libappindicator', 'libsecret']: }
  ->archive { '/tmp/vagrant-cache/slack-3.0.0-0.1.fc21.x86_64.rpm':
    ensure          => present,
    source          => 'https://downloads.slack-edge.com/linux_releases/slack-3.0.0-0.1.fc21.x86_64.rpm',
    extract         => true,
    extract_path    => '/tmp',
    extract_command => 'rpm -ivh %s',
    creates         => '/usr/bin/slack',
    checksum        => 'a849dcbb57cd38fb89633641320d9cad0dc65e5b3e67af9d514bc1b5b95e5c1b',
    checksum_type   => 'sha256',
    require         => File['/tmp/vagrant-cache'],
  }
}
