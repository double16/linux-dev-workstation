# Install the CircleCI CLI
# https://circleci.com/docs/2.0/local-jobs/
class private::circleci {
  remote_file { '/usr/local/bin/circleci':
    source => 'https://circle-downloads.s3.amazonaws.com/releases/build_agent_wrapper/circleci',
    mode   => '0755',
  }
}
