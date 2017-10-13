#
# $::proxy_url - the URL of the proxy server
# $::proxy_excludes - comma separated list of domains to exclude from the proxy
# $::ipv4only - true if network should be limited to IPV4
#
class private::proxy  {

  file { '/etc/sysctl.d/noipv6.conf':
    ensure  => str2bool($::ipv4only) ? { true => file, default => absent },
    content => '
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
'
  }

  file_line { 'Yum force ipv4':
    ensure => str2bool($::ipv4only) ? { true => present, default => absent },
    path   => '/etc/yum.conf',
    line   => 'ip_resolve=4',
  }
  -> Package<| provider == 'yum' |>

  $proxy_presence = $::proxy_url ? {
    /.+/    => present,
    default => absent,
  }

  unless empty($::search_domain) {
    file_line { 'search domain in /etc/resolve.conf':
      path  => '/etc/resolv.conf',
      line  => "search ${::search_domain}",
      match => '^search\s+',
    }
  }

  file_line { 'http_proxy in global environment':
    ensure            => $proxy_presence,
    path              => '/etc/environment',
    line              => "http_proxy=${::proxy_url}",
    match             => '^http_proxy\=',
    match_for_absence => true,
    multiple          => true,
  }
  file_line { 'https_proxy in global environment':
    ensure            => $::proxy_url ? { /^https:/ => present, default => absent},
    path              => '/etc/environment',
    line              => "https_proxy=${::proxy_url}",
    match             => '^https_proxy\=',
    match_for_absence => true,
    multiple          => true,
  }
  file_line { 'no_proxy in global environment':
    ensure            => $proxy_presence,
    path              => '/etc/environment',
    line              => "no_proxy=localhost,.localdomain,.local,127.0.0.1,${::proxy_excludes}",
    match             => '^no_proxy\=',
    match_for_absence => true,
    multiple          => true,
  }
  file_line { 'Yum proxy':
    ensure            => $proxy_presence,
    path              => '/etc/yum.conf',
    line              => "proxy=${::proxy_url}",
    match             => '^proxy\=',
    match_for_absence => true,
  }
  -> Package<| provider == 'yum' |>

  ini_setting { 'pip proxy':
    ensure  => $proxy_presence,
    path    => '/etc/xdg/pip/pip.conf',
    section => 'global',
    setting => 'proxy',
    value   => $::proxy_url,
    require => File['/etc/xdg/pip/pip.conf'],
  }
  -> Package<| provider == 'pip' or provider == 'pip2' or provider == 'pip3' |>

  file { '/root/.curlrc':
    ensure => file,
    owner  => 0,
    group  => 'root',
    mode   => '0640',
  }
  -> file_line { 'curl proxy for root':
    ensure            => $proxy_presence,
    path              => '/root/.curlrc',
    line              => "proxy = ${::proxy_url}",
    match             => '^proxy\s*=',
    match_for_absence => true,
  }
  -> Exec<| |>

  file { '/home/vagrant/.curlrc':
    ensure => file,
    owner  => 'nobody',
    group  => 'root',
    mode   => '0444',
  }
  -> file_line { 'curl proxy for vagrant':
    ensure            => $proxy_presence,
    path              => '/home/vagrant/.curlrc',
    line              => "proxy = ${::proxy_url}",
    match             => '^proxy\s*=',
    match_for_absence => true,
  }
  -> Exec<| |>

  unless empty($::proxy_url) { 
    git::config { 'http.proxy':
      value   => $::proxy_url,
      user    => 'root',
      scope   => 'system',
      before  => [ Class['nodenv'], Class['rbenv'] ],
      require => Class['Private::Git_from_source'],
    }
  } else {
    # TODO: remove git proxy
  }
 
  if $::proxy_url {

    Nodenv::Plugin<| |>
    ->Nodenv::Build<| |>
    ->exec { 'npm proxy':
      path    => ['/bin','/sbin/','/usr/bin','/usr/sbin','/opt/nodenv/bin','/opt/nodenv/shims'],
      # nodenv each plugin isn't recognized during the first run??
      #command => "nodenv each npm config set proxy $::proxy_url",
      command => "ls /opt/nodenv/versions/*/bin/node | xargs -L 1 -I {} npm config set proxy ${::proxy_url}",
    }
    ->Nodenv::Package<| |>

    Archive {
      proxy_server => $::proxy_url,
      proxy_type   => $::proxy_url ? { /^https:/ => 'https', default => 'http'},
    }

  } else {

    Nodenv::Plugin<| |>
    ->Nodenv::Build<| |>
    ->exec { 'npm proxy':
      path    => ['/bin','/sbin/','/usr/bin','/usr/sbin','/opt/nodenv/bin','/opt/nodenv/shims'],
      # nodenv each plugin isn't recognized during the first run??
      #command => "nodenv each npm config delete proxy",
      command => "ls /opt/nodenv/versions/*/bin/node | xargs -L 1 -I {} npm config delete proxy",
    }
    ->Nodenv::Package<| |>

  }
}
