# NetBeans IDE, application and plugins.
class private::netbeans {
  # http://download.netbeans.org/netbeans/8.2/final/zip/netbeans-8.2-201609300101.zip
  $config = lookup('netbeans', Hash)
  $version = $config['version']
  $build = $config['build']
  $checksum = $config['checksum']

  $prefsrootdir = '/home/vagrant/.netbeans'
  $prefsdir = "${prefsrootdir}/${version}"
  $vardir = "${prefsdir}/var"
  $confdir = "${prefsdir}/config"

  file { '/usr/local/bin/netbeans-modules-update.sh':
    ensure => file,
    mode   => '0755',
    owner  => 0,
    group  => 'root',
    source => 'puppet:///modules/private/netbeans-modules-update.sh',
  }

  file { '/opt/netbeans-plugins.txt':
    ensure => file,
    mode   => '0644',
    owner  => 0,
    group  => 'root',
    source => 'puppet:///modules/private/netbeans-plugins.txt',
  }

  file { [ $prefsrootdir, $prefsdir, $vardir ] :
    ensure => directory,
    owner  => 'vagrant',
    group  => 'vagrant',
  }

  file { "${vardir}/license_accepted":
    ensure  => file,
    owner   => 'vagrant',
    group   => 'vagrant',
    mode    => '0664',
    content => 'accepted by automation',
  }

  archive { "/tmp/vagrant-cache/netbeans-${version}-${build}.zip":
    ensure        => present,
    source        => "http://download.netbeans.org/netbeans/${version}/final/zip/netbeans-${version}-${build}.zip",
    checksum      => $checksum,
    checksum_type => 'sha256',
    extract_path  => '/opt',
    extract       => true,
    cleanup       => false,
    creates       => '/opt/netbeans/bin/netbeans',
    require       => File['/tmp/vagrant-cache'],
  }
  ~>exec { '/usr/local/bin/netbeans-modules-update.sh':
    refreshonly => true,
    timeout     => 900,
    user        => 'vagrant',
    cwd         => '/home/vagrant',
    environment => ['HOME=/home/vagrant'],
    require     => [
      File['/usr/local/bin/netbeans-modules-update.sh'],
      File['/opt/netbeans-plugins.txt'],
      File["${vardir}/license_accepted"],
      Exec['NetBeans Solarized'],
      Yum::Group['X Window System'] ],
  }

  $global_color_scheme = pick($::theme, lookup('theme::default')) ? {
    /light/ => 'Netbeans_Solarized_Light',
    /dark/  => 'Netbeans_Solarized_Dark',
    /none/  => '',
    default => undef,
  }

  vcsrepo { '/tmp/vagrant-cache/netbeans-colors-solarized':
    ensure   => present,
    provider => git,
    source   => 'https://github.com/fentie/netbeans-colors-solarized.git',
    user     => 'vagrant',
    require  => [ File[$prefsdir] ],
  }
  unless empty($global_color_scheme) {
    augeas { 'NetBeans Solarized Theme':
      lens    => 'Xml.lns',
      incl    => '/tmp/vagrant-cache/netbeans-colors-solarized/config/.nbattrs',
      context => '/files/tmp/vagrant-cache/netbeans-colors-solarized/config/.nbattrs',
      changes => [
        "set attributes/fileobject[#attribute[name=\"Editors\"]]/attr[#attribute[name=\"currentFontColorProfile\"]]/#attribute/stringvalue ${global_color_scheme}",
      ],
      require => Vcsrepo['/tmp/vagrant-cache/netbeans-colors-solarized'],
    }
    ~>exec { 'NetBeans Solarized':
      path    => ['/bin','/sbin','/usr/bin','/usr/sbin'],
      command => "mkdir -p ${confdir} && rsync -r /tmp/vagrant-cache/netbeans-colors-solarized/config/ ${confdir}/",
      creates => "${confdir}/Editors",
      user    => 'vagrant',
    }
  }

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
',
  }
}
