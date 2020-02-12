#
# Install R language things
#
class private::rlang {
  $config = lookup('rstudio', Hash)
  $version = $config['version']
  $checksum = $config['checksum']

  package { [ 'R', 'gstreamer1', 'gstreamer1-plugins-base' ]: }
  ->archive { "/tmp/vagrant-cache/rstudio-${version}-x86_64.rpm":
    ensure          => present,
    source          => "https://download1.rstudio.org/desktop/fedora28/x86_64/rstudio-${version}-x86_64.rpm",
    extract         => true,
    cleanup         => false,
    extract_path    => '/tmp',
    extract_command => 'rpm -ivh %s',
    creates         => '/usr/bin/rstudio',
    checksum        => $checksum,
    checksum_type   => 'sha256',
    require         => File['/tmp/vagrant-cache'],
  }
}
