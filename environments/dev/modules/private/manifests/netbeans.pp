class private::netbeans {
  # http://download.netbeans.org/netbeans/8.2/final/zip/netbeans-8.2-201609300101.zip
  $version = '8.2'
  $build = '201609300101'

  archive { "/tmp/vagrant-cache/netbeans-${version}-${build}.zip":
    ensure        => present,
    source        => "http://download.netbeans.org/netbeans/${version}/final/zip/netbeans-${version}-${build}.zip",
    checksum      => 'ad9888334b9a6c1f1138dcb2eccc8ce4921463e871e46def4ecc617538160948',
    checksum_type => 'sha256',
    extract_path  => '/opt',
    extract       => true,
    creates       => '/opt/netbeans/bin/netbeans',
  }
  ->file { '/usr/share/applications/NetBeans.desktop':
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
',
  }
}
