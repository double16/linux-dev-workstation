#
# rust lang and packages made in rust
#
class private::rust {
  $rust_packages = ['bat']
  $rust_packages_sum = sha256(join($rust_packages, ','))
  $cache_file = "/tmp/vagrant-cache/rust-${rust_packages_sum}.tgz"

  exec { 'restore cache for rust packages':
    command => "/usr/bin/tar xzf \"${cache_file}\" -C /root",
    onlyif  => "/usr/bin/find \"${cache_file}\" -mtime -30 | grep -q .",
    creates => '/root/.cargo',
    before  => Package['cargo'],
  }

  exec { 'save cache for rust packages':
    command     => "/bin/rm -f \"${cache_file}\" ; /usr/bin/tar czf \"${cache_file}\" -C /root .cargo",
    refreshonly => true,
    require     => File['/tmp/vagrant-cache'],
    onlyif      => '/usr/bin/mountpoint /tmp/vagrant-cache',
  }

  class deps {
    package { ['rust', 'cargo', 'llvm-devel']: }

    package { 'clang': }
    ->file { '/etc/ld.so.conf.d/clang6-private-x86_64.conf':
      ensure  => file,
      owner   => 0,
      group   => 'root',
      mode    => '0644',
      content => '/usr/lib64/clang-private
',
    }
    ~>exec { 'ld.so cache for clang':
      command     => '/usr/sbin/ldconfig',
      refreshonly => true,
    }
  }
  include private::rust::deps

  $rust_packages.each |$pkg| {
    exec { $pkg:
      command => "/usr/bin/cargo install --root /usr/local ${pkg}",
      creates => "/usr/local/bin/${pkg}",
      timeout => 1200,
      require => [ Class['private::rust::deps'], Exec['restore cache for rust packages'] ],
      notify  => Exec['save cache for rust packages'],
    }
  }
}
