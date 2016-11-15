class svn {
  file { '/etc/yum.repos.d/wandisco-svn.repo':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => '[WandiscoSVN]
name=Wandisco SVN Repo
baseurl=http://opensource.wandisco.com/centos/$releasever/svn-1.9/RPMS/$basearch/
enabled=1
gpgcheck=0',
  }
}
