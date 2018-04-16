#
# Install R language things
#
class private::rlang {
  package { [ 'R', 'gstreamer', 'gstreamer-plugins-base' ]: }
  ->archive { '/tmp/vagrant-cache/rstudio-1.1.442-x86_64.rpm':
    ensure          => present,
    source          => 'https://download1.rstudio.org/rstudio-1.1.442-x86_64.rpm',
    extract         => true,
    extract_path    => '/tmp',
    extract_command => 'rpm -ivh %s',
    creates         => '/usr/bin/rstudio',
    checksum        => '8e6435aa53fa0ea9878ef9c09b6419f4',
    checksum_type   => 'md5',
    require         => File['/tmp/vagrant-cache'],
  }
}
