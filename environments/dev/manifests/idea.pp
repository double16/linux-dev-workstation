class idea {
  $version = '2016.2.5'
  $build = '162.2228.15'

  archive { "idea-${version}":
    ensure           => present,
    url              => "http://download.jetbrains.com/idea/ideaIU-${version}.tar.gz",
    checksum         => false,
    src_target       => '/var/tmp',
    target           => '/opt',
    root_dir         => "idea-IU-${build}",
    extension        => 'tar.gz',
    timeout          => 3600,
    follow_redirects => true,
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
}
