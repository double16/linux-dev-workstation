# Slack chat application
class private::slack {
  $config = lookup('slack', Hash)
  $version = $config['version']
  $checksum = $config['checksum']

  package { ['libappindicator', 'libsecret']: }
  ->archive { "/tmp/vagrant-cache/slack-${version}.fc21.x86_64.rpm":
    ensure          => present,
    source          => "https://downloads.slack-edge.com/linux_releases/slack-${version}.fc21.x86_64.rpm",
    extract         => true,
    cleanup         => false,
    extract_path    => '/tmp',
    extract_command => 'rpm -ivh %s',
    creates         => '/usr/bin/slack',
    checksum        => $checksum,
    checksum_type   => 'sha256',
    require         => File['/tmp/vagrant-cache'],
  }
}
