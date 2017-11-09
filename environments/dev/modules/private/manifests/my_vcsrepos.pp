#
# Ensures source code repos are present using configuration in /vagrant/repos.yaml. The yaml file must be a map
# of 'vcsrepo' resources. See https://forge.puppet.com/puppetlabs/vcsrepo for details.
#
class private::my_vcsrepos {
  $repos_file = '/vagrant/repos.yaml'
  $repos = Hash(loadyaml($repos_file, {}).map |$name, $value| { ["/home/vagrant/Workspace/${name}", $value] })

  # Add host keys for SSH based repos
  $ssh_hosts = unique($repos
    .map |$repo, $repodetails| { $repodetails['source'] }
    .filter |$source| { !empty($source) }
    .map |$source| {
      debug("checking if ${source} is using SSH")
      $match_ssh_proto = $source.match(/ssh:\/\/[A-Za-z0-9_-]+@([A-Za-z0-9_.-]+)(?::([0-9]+))?\/.*/)
      $match_no_proto = $source.match(/[A-Za-z0-9_-]+@([A-Za-z0-9_.-]+):.*/)

      debug("match_ssh_proto = ${match_ssh_proto}")
      debug("match_no_proto = ${match_no_proto}")

      if empty($match_ssh_proto) {
        if empty($match_no_proto) {
          undef
        } else {
          "${match_no_proto[1]}:22"
        }
      } else {
        "${match_ssh_proto[1]}:${pick($match_ssh_proto[2], 22)}"
      }
    }
    .filter |$source| { !empty($source) }
  )
  debug("vcs hosts = ${ssh_hosts}")

  $ssh_keyscan_opts = str2bool($::ipv4only) ? {
    true    => '-4',
    default => '',
  }

  $ssh_hosts.each |$host_s| {
    $host_spec = split($host_s, ':')
    $host_id = $host_spec[1] ? {
      '22'    => $host_spec[0],
      default => "[${host_spec[0]}]:${host_spec[1]}",
    }
    exec { "vcs host verification ${host_spec[0]}:${host_spec[1]}":
      path    => ['/bin','/sbin','/usr/bin','/usr/sbin'],
      command => "ssh-keyscan ${ssh_keyscan_opts} -p ${host_spec[1]} ${host_spec[0]} >> /home/vagrant/.ssh/known_hosts",
      user    => 'vagrant',
      unless  => "grep -qF '${host_id}' /home/vagrant/.ssh/known_hosts",
      require => File['/home/vagrant/.ssh'],
    }
    -> Vcsrepo<| |>
  }

  # Create vcsrepo resources
  ensure_resources('vcsrepo', $repos, {
    ensure  => present,
    user    => 'vagrant',
    group   => 'vagrant',
    require => [ Class['::private::proxy'], Class['::private::git_from_source'], ],
  })
}

