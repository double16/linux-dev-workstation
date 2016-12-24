class netbeans {
  # http://download.netbeans.org/netbeans/8.2/final/zip/netbeans-8.2-201609300101.zip
  $version = '8.2'
  $build = '201609300101'

  archive { "netbeans-${version}-${build}":
    ensure           => present,
    url              => "http://download.netbeans.org/netbeans/${version}/final/zip/netbeans-${version}-${build}.zip",
    checksum         => false,
    digest_string    => 'ad9888334b9a6c1f1138dcb2eccc8ce4921463e871e46def4ecc617538160948',
    digest_type      => 'sha256',
    src_target       => '/tmp/vagrant-cache',
    target           => '/opt',
    root_dir         => 'netbeans',
    extension        => 'zip',
    timeout          => 3600,
    follow_redirects => true,
  }->
  file { '/usr/share/applications/NetBeans.desktop':
    ensure  => file,
    content => '
[Desktop Entry]
Version=1.0
Type=Application
Name=NetBeans
GenericName=NetBeans IDE
Categories=Development
Comment=
Exec=/opt/netbeans/bin/netbeans
Icon=/opt/netbeans/nb/netbeans.icns
DocPath=/opt/netbeans/nb/shortcuts.pdf
Path=/opt/netbeans
Terminal=false
StartupNotify=true
'
  }
}
