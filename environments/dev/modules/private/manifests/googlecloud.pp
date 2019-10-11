# Google Cloud CLI
# From https://cloud.google.com/sdk/docs/quickstart-redhat-centos
class private::googlecloud {
  file { '/etc/yum.repos.d/google-cloud-sdk.repo':
    mode    => '0644',
    owner   => 0,
    group   => 'root',
    content => '[google-cloud-sdk]
name=Google Cloud SDK
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
',
  }
  ~>exec { 'Google Cloud SDK gpg key 1':
    command     => '/usr/bin/rpm --verbose --import https://packages.cloud.google.com/yum/doc/yum-key.gpg',
    logoutput   => true,
    refreshonly => true,
  }
  ~>exec { 'Google Cloud SDK gpg key 2':
    command     => '/usr/bin/rpm --verbose --import https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg',
    logoutput   => true,
    refreshonly => true,
  }
  -> Package<| |>

  package { 'google-cloud-sdk': }
}
