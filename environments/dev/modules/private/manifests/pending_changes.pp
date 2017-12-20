#
# Notifies the user of pending changes so it can be known if the box can be safely destroyed.
#
class private::pending_changes {
  package { 'yad': }
  ->file { '/usr/local/bin/check-for-changes.sh':
    ensure => file,
    source => 'puppet:///modules/private/check-for-changes.sh',
    mode   => '0755',
  }
  ->file { '/usr/local/bin/pending-changes-notifier.sh':
    ensure => file,
    source => 'puppet:///modules/private/pending-changes-notifier.sh',
    mode   => '0755',
  }
  ->file { '/var/local/pending-changes':
    ensure => directory,
    owner  => 'vagrant',
    group  => 'vagrant',
    mode   => '0775',
  }
  ->file { '/home/vagrant/.config/autostart':
    ensure => directory,
    owner  => 'vagrant',
    group  => 'vagrant',
    mode   => '0775',
  }
  ->file { '/home/vagrant/.config/autostart/pending-changes-notifier.desktop':
    ensure  => file,
    owner   => 'vagrant',
    group   => 'vagrant',
    mode    => '0775',
    content => '[Desktop Entry]
Version=1.0
Name=Pending Changes Notification
Type=Application
Exec=/usr/local/bin/pending-changes-notifier.sh
Icon=emblem-generic
Terminal=false
StartupNotify=false
Hidden=false
',
  }
  ->cron { 'pending-changes':
    command => '/usr/local/bin/check-for-changes.sh',
    user    => 'vagrant',
    minute  => '0',
  }
}
