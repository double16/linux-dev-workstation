#
# Install R language things
#
class private::rlang {
  package { [ 'R', 'gstreamer', 'gstreamer-plugins-base' ]: }
  ->archive { '/tmp/vagrant-cache/rstudio-1.1.383-x86_64.rpm':
    ensure          => present,
    source          => 'https://download1.rstudio.org/rstudio-1.1.383-x86_64.rpm',
    extract         => true,
    extract_path    => '/tmp',
    extract_command => 'rpm -ivh %s',
    creates         => '/usr/bin/rstudio',
    checksum        => 'ae400e2504ec9c5862343c24fe3cd61d',
    checksum_type   => 'md5',
    require         => File['/tmp/vagrant-cache'],
  }
}

