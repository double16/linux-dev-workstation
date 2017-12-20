# Azure CLI
# From https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest
class private::azure {
  Yum::Gpgkey <| title == '/etc/pki/rpm-gpg/RPM-GPG-KEY-microsoft.com' |>
  ->file { '/etc/yum.repos.d/azure-cli.repo':
    mode    => '0644',
    owner   => 0,
    group   => 'root',
    content => '[azure-cli]
name=Azure CLI
baseurl=https://packages.microsoft.com/yumrepos/azure-cli
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
',
  }
  ->package { 'azure-cli': }
}
