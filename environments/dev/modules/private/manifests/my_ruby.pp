class private::my_ruby {
  $ruby_ver = '2.1.10'

  class { '::rbenv':
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
  rbenv::gem { 'librarian-puppet': }
  rbenv::gem { 'puppet-lint': }
  rbenv::gem { 'generate-puppetfile': }

  package { 'augeas-devel': }
  ->rbenv::gem { 'ruby-augeas': }
}
