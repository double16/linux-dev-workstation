class private::idea {
  # https://download-cf.jetbrains.com/idea/ideaIU-${version}.tar.gz
  $version = '2017.2.5'
  $build = '172.4343.14'
  $prefsdir = '/home/vagrant/.IntelliJIdea2017.2'
  $colorsdir = "${prefsdir}/colors"

  file { '/etc/sysctl.d/idea.conf':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => 'fs.inotify.max_user_watches = 524288',
  }

  archive { "/tmp/vagrant-cache/idea-${version}.tar.gz":
    ensure        => present,
    source        => "http://download.jetbrains.com/idea/ideaIU-${version}.tar.gz",
    extract_path  => '/opt',
    extract       => true,
    creates       => "/opt/idea-IU-${build}/bin/idea.sh",
    checksum      => 'a08ff0adfad2e8008d42e92d09696e43a70566b544db6c6f872e5b4d20436d2c',
    checksum_type => 'sha256',
    require       => File['/tmp/vagrant-cache'],
  }
  ->file { '/opt/idea':
    ensure => link,
    target => "/opt/idea-IU-${build}",
  }
  ->file { '/usr/share/applications/IntelliJ IDEA.desktop':
    ensure  => file,
    content => '
[Desktop Entry]
Version=1.0
Type=Application
Name=IntelliJ IDEA
GenericName=IntelliJ IDEA
Categories=Development
Comment=
Exec=/opt/idea/bin/idea.sh
Icon=/opt/idea/bin/idea.png
DocPath=file:///opt/idea/help/ReferenceCard.pdf
Path=
Terminal=false
StartupNotify=true
',
  }

  file { $prefsdir:
    ensure => directory,
    owner  => 'vagrant',
    group  => 'vagrant',
  }
  ->file { $colorsdir:
    ensure => directory,
    owner  => 'vagrant',
    group  => 'vagrant',
  }

  remote_file { "${colorsdir}/Solarized Dark.icls":
    ensure  => present,
    source  => 'https://raw.githubusercontent.com/jkaving/intellij-colors-solarized/master/Solarized%20Dark.icls',
    owner   => 'vagrant',
    group   => 'vagrant',
    require => File[$colorsdir],
  }

  remote_file { "${colorsdir}/Solarized Light.icls":
    ensure  => present,
    source  => 'https://raw.githubusercontent.com/jkaving/intellij-colors-solarized/master/Solarized%20Light.icls',
    owner   => 'vagrant',
    group   => 'vagrant',
    require => File[$colorsdir],
  }
}
