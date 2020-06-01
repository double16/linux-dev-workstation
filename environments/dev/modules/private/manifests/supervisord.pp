#
# Specifics for using supervisord instead of systemd
#
class private::supervisord {
  Service {
    provider => 'supervisor',
  }

  file { '/etc/supervisord.d/crond.conf': 
    ensure => file,
    owner  => 0,
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///modules/private/supervisord-crond.conf',
    before => Service['crond'],
  }
  ->service { 'crond':
    enable => true,
  }

}
