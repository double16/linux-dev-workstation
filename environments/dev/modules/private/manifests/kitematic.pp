#
# Install Kitematic for use as a Docker UI. Kitematic is released as a debian package so we use `alien`
# to repackage it as an RPM.
#
class private::kitematic
{
  $config = lookup('kitematic', Hash)
  $version = $config['version']
  $checksum = $config['checksum']

  exec { 'atrpms-repo-7-7':
    command => '/usr/bin/rpm -i --nodeps https://www.mirrorservice.org/sites/dl.atrpms.net/el7-x86_64/atrpms/stable/atrpms-repo-7-7.el7.x86_64.rpm',
    creates => '/etc/yum.repos.d/atrpms.repo',
  }
  ->exec { 'atrpms mirror':
    command => '/usr/bin/sed -i -e \'s@^baseurl=http://dl.atrpms.net/@baseurl=https://www.mirrorservice.org/sites/dl.atrpms.net/@g\' /etc/yum.repos.d/atrpms*repo',
    onlyif  => '/usr/bin/grep -qF \'baseurl=http://dl.atrpms.net/\' /etc/yum.repos.d/atrpms*repo',
  }
  ->package { [ 'rpmrebuild', 'zsh', 'libnotify' ]: }
  ->exec { 'yum replace -y libmp3lame0 --replace-with=lame-libs':
    unless  => 'yum list installed lame-libs',
    path    => '/bin:/sbin:/usr/bin:/usr/sbin',
    require => [ Yum::Plugin['replace'] ],
  }
  ->package { [ 'ffmpeg-devel' ]: }
  ->archive { "/tmp/vagrant-cache/Kitematic-${version}.zip":
    ensure        => present,
    source        => "https://github.com/docker/kitematic/releases/download/v${version}/Kitematic-${version}-Ubuntu.zip",
    extract_path  => '/opt',
    extract       => true,
    extract_flags => '-oj',
    checksum      => $checksum,
    checksum_type => 'sha256',
    creates       => "/opt/Kitematic_${version}_amd64.deb",
    require       => File['/tmp/vagrant-cache'],
  }
  ->exec { 'Kitematic rpm':
    command => "/usr/bin/alien -r -k /opt/Kitematic_${version}_amd64.deb",
    creates => "/opt/kitematic-${version}-1.x86_64.rpm",
    cwd     => '/opt',
    timeout => 0,
    require => Package['alien'],
  }
  ->exec { 'Kitematic rpm fixes':
    command => join([
      '/usr/bin/rpmrebuild',
      '--verbose',
      '--batch',
      '--change-spec-files=\'grep -v "\\"/\\"\\|\\"/usr\\"\\|\\"/usr/bin\\"\\|\\"/usr/share\\"\\|\\"/usr/share/applications\\"\\|\\"/usr/share/doc\\"\\|\\"/usr/share/pixmaps\\""\'',
      '-p',
      "/opt/kitematic-${version}-1.x86_64.rpm"
    ], ' '),
    creates => "/rpmbuild/RPMS/x86_64/kitematic-${version}-1.x86_64.rpm",
    timeout => 0,
    require => Package['rpmrebuild'],
  }
  ->package { 'kitematic':
    ensure          => $version,
    source          => "/rpmbuild/RPMS/x86_64/kitematic-${version}-1.x86_64.rpm",
    provider        => 'rpm',
    install_options => '--nodeps',
  }
}
