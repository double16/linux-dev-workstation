class private::idea {
  # https://download-cf.jetbrains.com/idea/ideaIU-${version}.tar.gz
  $version = '2017.3.2'
  $build = '173.4127.27'
  $prefsdir = '/home/vagrant/.IntelliJIdea2017.3'
  $configdir = "${prefsdir}/config"
  $plugindir = "${configdir}/plugins"
  $colorsdir = "${configdir}/colors"

  file { '/etc/sysctl.d/idea.conf':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => 'fs.inotify.max_user_watches = 524288
',
  }

  archive { "/tmp/vagrant-cache/idea-${version}.tar.gz":
    ensure        => present,
    source        => "http://download.jetbrains.com/idea/ideaIU-${version}.tar.gz",
    extract_path  => '/opt',
    extract       => true,
    creates       => "/opt/idea-IU-${build}/bin/idea.sh",
    checksum      => 'ac87f00d467f002ed7ab3b94956d71ef493cd25f7ae7dcfa2e0cab9c4e8e9fd0',
    checksum_type => 'sha256',
    require       => File['/tmp/vagrant-cache'],
  }
  ->exec { "chown -R vagrant:vagrant /opt/idea-IU-${build}":
    path   => ['/bin','/sbin','/usr/bin','/usr/sbin','/usr/local/bin','/usr/local/sbin'],
    onlyif => "find /opt/idea-IU-${build} -not \\( -user vagrant -and -group vagrant \\) | grep -q '.'",
  }
  ->file { '/opt/idea':
    ensure => link,
    target => "/opt/idea-IU-${build}",
    owner  => 'vagrant',
    group  => 'vagrant',
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
  define plugin_zip($version, $updateid, $sha256sum = undef) {
    $checksum_type = $sha256sum ? {
      undef   => undef,
      default => 'sha256',
    }
    archive { "/tmp/vagrant-cache/idea-plugins/${title}-${version}.zip":
      ensure        => present,
      extract       => true,
      extract_path  => $::private::idea::plugindir,
      source        => "https://plugins.jetbrains.com/plugin/download?updateId=${updateid}",
      checksum      => $sha256sum,
      checksum_type => $checksum_type,
      creates       => "${::private::idea::plugindir}/${title}",
      cleanup       => false,
      user          => 'vagrant',
      group         => 'vagrant',
      require       => File['/tmp/vagrant-cache/idea-plugins'],
    }
  }

  define plugin_jar($version, $updateid, $sha256sum = undef) {
    $checksum_type = $sha256sum ? {
      undef   => undef,
      default => 'sha256',
    }
    remote_file { "${::private::idea::plugindir}/${title}.jar":
      ensure        => present,
      source        => "https://plugins.jetbrains.com/plugin/download?updateId=${updateid}",
      checksum      => $sha256sum,
      checksum_type => $checksum_type,
      owner         => 'vagrant',
      group         => 'vagrant',
      require       => File[$::private::idea::plugindir],
    }
  }

  private::idea::plugin_zip { 'LiveEdit':
    version  => '173.3942.31',
    updateid => '41376',
  }

  private::idea::plugin_zip { 'AngularJS':
    version  => '173.4127.22',
    updateid => '41668',
  }

  private::idea::plugin_zip { 'ruby':
    version  => '2017.3.20171205',
    updateid => '41245',
  }

  private::idea::plugin_zip { 'puppet':
    version  => '173.3727.127',
    updateid => '41058',
  }

  private::idea::plugin_zip { 'NodeJS':
    version  => '173.4127.22',
    updateid => '41666',
  }

  private::idea::plugin_zip { 'BashSupport':
    version  => '1.6.12.173',
    updateid => '38798',
  }

  private::idea::plugin_zip { 'Docker':
    version  => '173.3727.15',
    updateid => '40538',
  }

  private::idea::plugin_zip { 'idea-gitignore':
    version  => '2.3.2',
    updateid => '40625',
  }

  private::idea::plugin_zip { 'ini4idea':
    version  => '173.3727.84',
    updateid => '40770',
  }

  private::idea::plugin_zip { 'intellij-hcl':
    version  => '0.6.9.3',
    updateid => '41177',
  }

  private::idea::plugin_zip { 'intellij-go':
    version  => '173.3727.144',
    updateid => '41097',
  }

  private::idea::plugin_zip { 'Jade':
    version  => '173.3531.1',
    updateid => '40091',
  }

  private::idea::plugin_zip { 'asciidoctor':
    version  => '0.19.2',
    updateid => '40599',
  }

  private::idea::plugin_zip { 'Kotlin':
    version  => '1.2.10-release-IJ2017.3-1',
    updateid => '41422',
  }

  private::idea::plugin_zip { 'Bitbucket Linky':
    version  => '5.0',
    updateid => '40911',
  }

  private::idea::plugin_zip { 'Gradle Dependencies Helper':
    version  => '1.10',
    updateid => '42005',
  }

  private::idea::plugin_zip { 'R4Intellij':
    version  => '1.0.8',
    updateid => '37756',
  }

  private::idea::plugin_zip { 'js-karma':
    version  => '173.4127.22',
    updateid => '41670',
  }

  private::idea::plugin_zip { 'sass-lint-plugin':
    version  => '1.0.8',
    updateid => '40438',
  }

  private::idea::plugin_jar { 'react-css-modules-intellij-plugin':
    version  => '1.0.1',
    updateid => '30724',
  }

  private::idea::plugin_jar { 'bootstrap3':
    version  => '4.0.4',
    updateid => '39293',
  }

  private::idea::plugin_jar { 'com.jetbrains.ideolog-173.0.6.0':
    version  => '173.0.6.0',
    updateid => '42025',
  }

  private::idea::plugin_zip { 'vagrant':
    version  => '173.3727.127',
    updateid => '41069',
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

  file { "${configdir}/options/git.xml":
    ensure  => file,
    mode    => '0664',
    owner   => 'vagrant',
    group   => 'vagrant',
    replace => false,
    content => '
<application>
  <component name="Git.Application.Settings">
    <option name="myPathToGit" value="/usr/bin/git" />
    <option name="SSH_EXECUTABLE" value="NATIVE_SSH" />
  </component>
</application>',
  }
}
