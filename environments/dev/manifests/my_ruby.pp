class my_ruby {
  $ruby_ver = '2.1.9'

  class { 'rbenv':
    install_dir => '/opt/rbenv',
    latest      => true,
  }

  rbenv::plugin { 'sstephenson/ruby-build': latest => true }
  rbenv::build { $ruby_ver: global => true }

  Rbenv::Gem {
    ruby_version => $ruby_ver
  }

  rbenv::gem { 'rake': }
  rbenv::gem { 'librarian-puppet': }
  rbenv::gem { 'puppet-lint': }
  rbenv::gem { 'generate-puppetfile': }
}
