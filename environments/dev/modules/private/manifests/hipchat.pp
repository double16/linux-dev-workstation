# Atlassian HipChat
class private::hipchat {
  file { '/etc/yum.repos.d/hipchat.repo':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => '[atlassian-hipchat]
name=Atlassian Hipchat
baseurl=https://atlassian.artifactoryonline.com/atlassian/hipchat-yum-client/
enabled=1
gpgcheck=0
#gpgkey=https://www.hipchat.com/keys/hipchat-linux.key
',
  }
  ->package { 'hipchat4': }
}
