# Google Chrome
class private::googlechrome {
  file { '/etc/yum.repos.d/google-chrome.repo':
    replace => false,
    mode    => '0644',
    owner   => 0,
    group   => 'root',
    content => '[google-chrome]
name=google-chrome
baseurl=http://dl.google.com/linux/chrome/rpm/stable/$basearch
enabled=1
gpgcheck=1
gpgkey=https://dl-ssl.google.com/linux/linux_signing_key.pub
',
  }
  -> Package<| |>

  package { 'google-chrome-stable': }
}
