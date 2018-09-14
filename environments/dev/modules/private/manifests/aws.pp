# AWS CLI
# From http://docs.aws.amazon.com/cli/latest/userguide/installing.html
class private::aws {
  package { 'awscli':
    ensure   => present,
    provider => 'pip',
  }

  remote_file { '/usr/local/bin/ecs-cli':
    ensure => present,
    source => 'https://s3.amazonaws.com/amazon-ecs-cli/ecs-cli-linux-amd64-latest',
    mode   => '0755',
  }
}
