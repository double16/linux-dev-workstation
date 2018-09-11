# Install the CircleCI CLI
# https://circleci.com/docs/2.0/local-jobs/
class private::circleci {
  exec { 'circleci-cli':
    command     => '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/CircleCI-Public/circleci-cli/master/install.sh)"',
    creates     => '/usr/local/bin/circleci',
    environment => ['PATH=/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin'],
  }
  ->file { '/usr/local/bin/circleci':
    ensure => present,
    mode   => '0755',
    owner  => 0,
    group  => 'root',
  }
}
