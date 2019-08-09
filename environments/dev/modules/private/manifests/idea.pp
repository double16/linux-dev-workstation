#
# IntelliJ IDEA Ultimate and plugins
#
class private::idea {
  # https://download-cf.jetbrains.com/idea/ideaIU-${version}.tar.gz
  # https://download-cf.jetbrains.com/idea/ideaIC-${version}.tar.gz
  $config = lookup('idea', Hash)
  $version = $config['version']
  $build = $config['build']
  $checksum = $config['checksum']
  $checksumce = $config['checksum-ce']

  $version_parts = split($version, '[.]')
  $prefsdir = "/home/vagrant/.IntelliJIdea${version_parts[0]}.${version_parts[1]}"
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
    source        => "https://download-cf.jetbrains.com/idea/ideaIU-${version}.tar.gz",
    extract_path  => '/opt',
    extract       => true,
    creates       => "/opt/idea-IU-${build}/bin/idea.sh",
    checksum      => $checksum,
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
Comment=Capable and Ergonomic IDE (Ultimate Edition)
Exec=/opt/idea/bin/idea.sh
Icon=/opt/idea/bin/idea.png
DocPath=file:///opt/idea/help/ReferenceCard.pdf
Path=
Terminal=false
StartupNotify=true
',
  }

  archive { "/tmp/vagrant-cache/idea-ce-${version}.tar.gz":
    ensure        => present,
    source        => "https://download-cf.jetbrains.com/idea/ideaIC-${version}.tar.gz",
    extract_path  => '/opt',
    extract       => true,
    creates       => "/opt/idea-IC-${build}/bin/idea.sh",
    checksum      => $checksumce,
    checksum_type => 'sha256',
    require       => File['/tmp/vagrant-cache'],
  }
  ->exec { "chown -R vagrant:vagrant /opt/idea-IC-${build}":
    path   => ['/bin','/sbin','/usr/bin','/usr/sbin','/usr/local/bin','/usr/local/sbin'],
    onlyif => "find /opt/idea-IC-${build} -not \\( -user vagrant -and -group vagrant \\) | grep -q '.'",
  }
  ->file { '/opt/idea-ce':
    ensure => link,
    target => "/opt/idea-IC-${build}",
    owner  => 'vagrant',
    group  => 'vagrant',
  }
  ->file { '/usr/share/applications/IntelliJ IDEA CE.desktop':
    ensure  => file,
    content => '
[Desktop Entry]
Version=1.0
Type=Application
Name=IntelliJ IDEA CE
GenericName=IntelliJ IDEA Community Edition
Categories=Development
Comment=Capable and Ergonomic IDE (Community Edition)
Exec=/opt/idea-ce/bin/idea.sh
Icon=/opt/idea-ce/bin/idea.png
DocPath=file:///opt/idea-ce/help/ReferenceCard.pdf
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
    unless $::facts['ideaplugins'].dig($title, 'version') == "${version}" {
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
  }

  define plugin_jar($version, $updateid, $sha256sum = undef) {
    $checksum_type = $sha256sum ? {
      undef   => undef,
      default => 'sha256',
    }
    unless $::facts['ideaplugins'].dig($title, 'version') == "${version}" {
      private::cached_remote_file { "${::private::idea::plugindir}/${title}.jar":
        cache_name    => "idea-plugins/${title}-${version}.jar",
        source        => "https://plugins.jetbrains.com/plugin/download?updateId=${updateid}",
        checksum      => $sha256sum,
        checksum_type => $checksum_type,
        owner         => 'vagrant',
        group         => 'vagrant',
        require       => File[$::private::idea::plugindir],
      }
    }
  }

  $config['plugins'].each |$item| {
      $plugin_name = $item['name']
      $plugin_type = $item['type']
      $plugin_version = $item['version']
      $plugin_updateid = $item['updateid']

      if $plugin_type == 'jar' {
        private::idea::plugin_jar { $plugin_name:
          version  => $plugin_version,
          updateid => $plugin_updateid,
        }
      } else {
        private::idea::plugin_zip { $plugin_name:
          version  => $plugin_version,
          updateid => $plugin_updateid,
        }
      }
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

  $global_color_scheme = pick($::theme, lookup('theme::default')) ? {
    /light/ => 'Solarized Light',
    /dark/  => 'Solarized Dark',
    /none/  => '',
    default => undef,
  }
  if empty($::theme) {
    file { "${configdir}/options/colors.scheme.xml":
      ensure  => file,
      mode    => '0664',
      owner   => 'vagrant',
      group   => 'vagrant',
      replace => false,
      content => "
  <application>
    <component name=\"EditorColorsManagerImpl\">
      <global_color_scheme name=\"${global_color_scheme}\" />
    </component>
  </application>",
    }
  } else {
    if empty($global_color_scheme) {
      $global_color_scheme_changes = [
          "rm component[#attribute/name=\"EditorColorsManagerImpl\"]/global_color_scheme",
      ]
    } else {
      $global_color_scheme_changes = [
          "set component[#attribute/name=\"EditorColorsManagerImpl\"]/global_color_scheme/#attribute/name \"${global_color_scheme}\"",
      ]
    }
    augeas { 'idea theme':
      incl    => "${configdir}/options/colors.scheme.xml",
      lens    => "Xml.lns",
      context => "/files/${configdir}/options/colors.scheme.xml/application",
      changes => $global_color_scheme_changes,
    }
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
