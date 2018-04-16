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
    checksum        => '331addcbbe1b33843df68e1d16fbd66c7a774459d3f6113fb3e6b3e3cb8e2437',
    checksum_type   => 'md5',
    require         => File['/tmp/vagrant-cache'],
  }
}
