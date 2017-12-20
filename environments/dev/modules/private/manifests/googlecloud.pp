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
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
',
  }
  ->package { 'google-cloud-sdk': }
}
