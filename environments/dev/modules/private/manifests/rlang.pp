#
# Install R language things
#
class private::rlang {
  package { [ 'R', 'gstreamer', 'gstreamer-plugins-base' ]: }
  ->archive { '/tmp/vagrant-cache/rstudio-1.1.423-x86_64.rpm':
    ensure          => present,
    source          => 'https://download1.rstudio.org/rstudio-1.1.423-x86_64.rpm',
    extract         => true,
    extract_path    => '/tmp',
    extract_command => 'rpm -ivh %s',
    creates         => '/usr/bin/rstudio',
    checksum        => '8d3d8c49260539a590d8eeea555eab08',
    checksum_type   => 'md5',
    require         => File['/tmp/vagrant-cache'],
  }
}
