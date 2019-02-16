#
# Install Dockstation for use as a Docker UI.
#
class private::dockstation {
  $config = lookup('dockstation', Hash)
  $version = $config['version']
  $checksum = $config['checksum']
  $file = "dockstation-${version}-x86_64.AppImage"
  $install_file = "/usr/local/share/${file}"

  package { [ 'fuse', 'squashfuse' ]:}

  private::cached_remote_file { $install_file:
    cache_name    => $file,
    source        => "https://github.com/DockStation/dockstation/releases/download/v${version}/${file}",
    checksum      => $checksum,
    checksum_type => 'sha256',
    owner         => 0,
    group         => 'root',
    mode          => '0755',
  }

  file { [
    '/home/vagrant/.local',
    '/home/vagrant/.local/share',
    '/home/vagrant/.local/share/applications'
    ]:
    ensure => directory,
    owner  => 'vagrant',
    group  => 'vagrant',
    mode   => '0755',
  }

  file { ['/usr/local/share/applications/appimagekit-dockstation.desktop','/home/vagrant/.local/share/applications/appimagekit-dockstation.desktop']:
    ensure => file,
    owner  => 0,
    group  => 'root',
    mode   => '0644',
    content => "
[Desktop Entry]
Name=DockStation
Comment=Working with Docker has never been so easy and convenient.
Exec=${install_file} %U
Terminal=false
Type=Application
Icon=appimagekit-dockstation
X-AppImage-Version=1.24
X-AppImage-BuildId=95a27910-3222-11a8-0fe9-03482e3e7037
Categories=Development;
X-Desktop-File-Install-Version=0.23
X-AppImage-Comment=Generated by Puppet
TryExec=${install_file}
",
  }
}