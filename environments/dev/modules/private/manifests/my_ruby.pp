#
# Ruby Versions and gems
#
class private::my_ruby {
  $ruby_ver = '2.1.10'

  file { '/tmp/vagrant-cache/rbenv':
    ensure => directory,
    mode   => '0777',
    owner  => 'vagrant',
    group  => 'vagrant',
  }
  ->file_line { 'RUBY_BUILD_CACHE_PATH':
    path  => '/etc/environment',
    line  => 'RUBY_BUILD_CACHE_PATH=/tmp/vagrant-cache/rbenv',
    match => '^RUBY_BUILD_CACHE_PATH\=',
  }
  ->class { '::rbenv':
    install_dir => '/opt/rbenv',
    latest      => true,
    require     => Class['private::git_from_source'],
  }

  rbenv::plugin { 'rbenv/ruby-build': latest => true }
  rbenv::plugin { 'sstephenson/ruby-build': latest => true }
  rbenv::build { $ruby_ver: global => true }
  rbenv::build { '1.9.3-p551': }
  rbenv::build { 'jruby-1.7.26': }
  rbenv::build { '2.4.2': }
  rbenv::build { '2.3.5': }
  rbenv::build { 'jruby-9.1.13.0': }

  Rbenv::Gem {
    ruby_version => $ruby_ver,
  }

  rbenv::gem { 'rake': }
  rbenv::gem { 'librarian-puppet':
    version => '>=3.0.0',
  }
  rbenv::gem { 'librarianp':
    version => '>=0.6.4',
  }
  rbenv::gem { 'puppet-lint': }
  rbenv::gem { 'generate-puppetfile': }

  package { 'augeas-devel': }
  ->rbenv::gem { 'ruby-augeas': }
}
