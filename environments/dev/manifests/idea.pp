class idea {
  # https://download-cf.jetbrains.com/idea/ideaIU-2016.3.5.tar.gz
  $version = '2016.3.5'
  $build = '163.13906.18'
  $prefsdir = '/home/vagrant/.IntelliJIdea2016.3'
  $colorsdir = "${prefsdir}/colors"

  archive { "idea-${version}":
    ensure           => present,
    url              => "http://download.jetbrains.com/idea/ideaIU-${version}.tar.gz",
    checksum         => false,
    src_target       => '/tmp/vagrant-cache',
    target           => '/opt',
    root_dir         => "idea-IU-${build}",
    extension        => 'tar.gz',
    timeout          => 3600,
    follow_redirects => true,
  }

  file { '/etc/sysctl.d/idea.conf':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => 'fs.inotify.max_user_watches = 524288',
  }

  file { '/opt/idea':
    ensure  => link,
    target  => "/opt/idea-IU-${build}",
    require => Archive["idea-${version}"],
  }->
  file { '/usr/share/applications/IntelliJ IDEA.desktop':
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
'
  }

  file { $prefsdir:
    ensure => directory,
    owner  => 'vagrant',
    group  => 'vagrant',
  }->
  file { $colorsdir:
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
