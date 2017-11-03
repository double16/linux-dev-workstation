class private::idea {
  # https://download-cf.jetbrains.com/idea/ideaIU-${version}.tar.gz
  $version = '2017.2.5'
  $build = '172.4343.14'
  $prefsdir = '/home/vagrant/.IntelliJIdea2017.2'
  $configdir = "${prefsdir}/config"
  $plugindir = "${configdir}/plugins"
  $colorsdir = "${configdir}/colors"

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

  file { [ $prefsdir, $configdir, $colorsdir, $plugindir, "${configdir}/options" ] :
    ensure => directory,
    owner  => 'vagrant',
    group  => 'vagrant',
  }

  file { '/tmp/vagrant-cache/idea-plugins':
    ensure => directory,
    mode   => '0755',
    owner  => 'vagrant',
    group  => 'vagrant',
  }

  # Find plugin at https://plugins.jetbrains.com/idea
  # Copy direct download link
  # To get the sha256 sum: curl -L ${url} | shasum -a 256
  define plugin_zip($version, $updateid, $sha256sum) {
    archive { "/tmp/vagrant-cache/idea-plugins/${title}-${version}.zip":
      ensure        => present,
      extract       => true,
      extract_path  => $::private::idea::plugindir,
      source        => "https://plugins.jetbrains.com/plugin/download?updateId=${updateid}",
      checksum      => $sha256sum,
      checksum_type => 'sha256',
      creates       => "${::private::idea::plugindir}/${title}",
      cleanup       => false,
      user          => 'vagrant',
      group         => 'vagrant',
      require       => File['/tmp/vagrant-cache/idea-plugins'],
    }
  }

  define plugin_jar($version, $updateid, $sha256sum) {
    remote_file { "${::private::idea::plugindir}/${title}.jar":
      ensure        => present,
      source        => "https://plugins.jetbrains.com/plugin/download?updateId=${updateid}",
      checksum      => $sha256sum,
      checksum_type => 'sha256',
      owner         => 'vagrant',
      group         => 'vagrant',
      require       => File[$::private::idea::plugindir],
    }
  }

  private::idea::plugin_zip { 'LiveEdit':
    version   => '172.4343.25',
    updateid  => '39751',
    sha256sum => '1f3afcec669cb044d65889dc6b8224f5af0b8b3f2c165fdaefb6869896c08778',
  }

  private::idea::plugin_zip { 'AngularJS':
    version   => '172.4155.35',
    updateid  => '39192',
    sha256sum => '9eaecf1eeb47d26b7bbe745b1aaa23a3a38b3e3e721705eafcef9a61a4808318',
  }

  private::idea::plugin_zip { 'ruby':
    version   => '2017.2.20170906',
    updateid  => '38512',
    sha256sum => '6544f712f9191a0bffd787f3d6a698902300bce0b960e6ac07db19ab95c691bf',
  }

  private::idea::plugin_zip { 'puppet':
    version   => '172.3317.76',
    updateid  => '36968',
    sha256sum => '2f1a0affbc9d6888aed79968106522628fbaf016100ad9223371de1a9c1aa803',
  }

  private::idea::plugin_zip { 'NodeJS':
    version   => '172.4155.10',
    updateid  => '38475',
    sha256sum => '2d6aba4e51fa274ecd518e73851439c3a3df60fb88e374d81a6cddb535f9aabd',
  }

  private::idea::plugin_zip { 'BashSupport':
    version   => '1.6.12.172',
    updateid  => '38357',
    sha256sum => 'dd5e347ffe07f4e7c5464dab7c9128f64d970a35599e4e85b801663206bec2b9',
  }

  private::idea::plugin_zip { 'Docker':
    version   => '172.3968.28',
    updateid  => '38244',
    sha256sum => 'e6d3d3db8977fee9eb31c193843acb7cf7bd5126b499da8e0df40f1cbdbe2e7c',
  }

  private::idea::plugin_zip { 'idea-gitignore':
    version   => '2.3.0',
    updateid  => '40109',
    sha256sum => '207d45fe2c284a516fd677689bf26b7b31cf41c7e36d6bd1e4a034c125186610',
  }

  private::idea::plugin_zip { 'ini4idea':
    version   => '172.3317.57',
    updateid  => '36822',
    sha256sum => 'b96c53ed3e7d56d5b46ffe0f2301bfa2360da0cd5a1692b1b8c7dc0dabdfb90c',
  }

  private::idea::plugin_zip { 'intellij-hcl':
    version   => '0.6.8',
    updateid  => '40107',
    sha256sum => 'b09668f87b325f491190b69dbfe8da50450ddf29f0495e1bc4753358551cb573',
  }

  private::idea::plugin_zip { 'intellij-go':
    version   => '172.3968.45',
    updateid  => '38446',
    sha256sum => 'd2a64e992183399e4a5ff536691fad1a0e7b17cae7a1770f51cb676bfe3b4c9a',
  }

  private::idea::plugin_zip { 'Jade':
    version   => '172.2656.13',
    updateid  => '35649',
    sha256sum => '8e9a8bc3b4b2187f3946a98d65436c1945cad4804dc3eeecfd4eb776b4a4b5b6',
  }

  private::idea::plugin_zip { 'asciidoctor':
    version   => '0.19.1',
    updateid  => '38643',
    sha256sum => 'd5cadedc343039c8d2a6b0a6db35da55f502c68895cb3a265eeb32cca586e0f8',
  }

  private::idea::plugin_zip { 'Kotlin':
    version   => '1.1.51-release-IJ2017.2-1',
    updateid  => '39169',
    sha256sum => '55474130f14543ce3059096079659c2e843b422625548a451a0f3b7717d0b09c',
  }

  private::idea::plugin_zip { 'Bitbucket Linky':
    version   => '4.1',
    updateid  => '39954',
    sha256sum => 'c20393d6af058355a3904e7892b67d1c6e0e66bf8fc2873b3e59a718bee5bcc0',
  }

  private::idea::plugin_zip { 'GradleDependencySupport':
    version   => '1.8',
    updateid  => '31587',
    sha256sum => 'b1708f1536d452e8276c796810f2191a5b1dd083a78fccb2b2342e5ff723f310',
  }

  private::idea::plugin_zip { 'R4Intellij':
    version   => '1.0.8',
    updateid  => '37756',
    sha256sum => '0ad3db61e99a95b7046344f2c0df11668c14255d379c02cd3736a5bf417f5055',
  }

  private::idea::plugin_zip { 'js-karma':
    version   => '172.3968.20',
    updateid  => '38070',
    sha256sum => 'a1776aafd92a3d74e35e924cd72ac11bd615c5f0e2a5374bb107d217df41f963',
  }

  private::idea::plugin_zip { 'sass-lint-plugin':
    version   => '1.0.7',
    updateid  => '39734',
    sha256sum => '2b49c19e1f314fb2e8a312470e59d652b4216bcb34ceae49e22bbfd7aae5e3c3',
  }

  private::idea::plugin_jar { 'react-css-modules-intellij-plugin':
    version   => '1.0.1',
    updateid  => '30724',
    sha256sum => '6aa617ab4a8caeaa93142a3b8924d81fb6da9024d0d6f618b59c05696730cf4e',
  }

  private::idea::plugin_jar { 'bootstrap3':
    version   => '4.0.4',
    updateid  => '39293',
    sha256sum => '2dfdb0d2c5263299458a355b5749f2d74d8a18c675e8a575a7d74b87eea34b68',
  }

  private::idea::plugin_jar { 'com.jetbrains.ideolog-172.0.4.0':
    version   => '172.0.4.0',
    updateid  => '38886',
    sha256sum => 'ff5b77aa78d14018a0295daab1e08b3496d264f3f18cf34bc424a872648238a9',
  }

  private::idea::plugin_zip { 'vagrant':
    version   => '172.3317.76',
    updateid  => '37002',
    sha256sum => '3e52f3139ab8de92346f58c781bb88b75ea3af0f81d566464f60f8d1ba4cbb90',
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

  file { "${configdir}/options/colors.scheme.xml":
    ensure  => file,
    mode    => '0664',
    owner   => 'vagrant',
    group   => 'vagrant',
    replace => false,
    content => '
<application>
  <component name="EditorColorsManagerImpl">
    <global_color_scheme name="Solarized Light" />
  </component>
</application>',
  }
}
