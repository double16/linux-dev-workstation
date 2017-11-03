#
# Install R language things
#
class private::rlang {
  package { 'R': }

  package { ['gstreamer', 'gstreamer-plugins-base' ]: }
  ->remote_file { '/tmp/vagrant-cache/rstudio-1.1.383-x86_64.rpm':
    ensure        => present,
    source        => 'https://download1.rstudio.org/rstudio-1.1.383-x86_64.rpm',
    checksum      => 'ae400e2504ec9c5862343c24fe3cd61d',
    checksum_type => 'md5',
  }
  ->package { 'rstudio':
    source   => '/tmp/vagrant-cache/rstudio-1.1.383-x86_64.rpm',
    provider => 'rpm',
  }
}

