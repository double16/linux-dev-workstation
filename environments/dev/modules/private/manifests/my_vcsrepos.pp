#
# Ensures source code repos are present using configuration in /vagrant/repos.yaml. The yaml file must be a map
# of 'vcsrepo' resources. See https://forge.puppet.com/puppetlabs/vcsrepo for details.
#
class private::my_vcsrepos {
  $repos_file = '/vagrant/repos.yaml'
  $repos = Hash(loadyaml($repos_file, {}).map |$name, $value| { ["/home/vagrant/Workspace/${name}", $value] })
  ensure_resources('vcsrepo', $repos, {
    ensure  => present,
    user    => 'vagrant',
    group   => 'vagrant',
    require => [ Class['::private::proxy'], Class['::private::git_from_source'], ],
  })
}

