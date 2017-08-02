class clean {
  cron { 'clean_systemd_journal':
    command => 'find /var/log/journal/ -mtime +7 -delete',
    user    => 'root',
    special => 'daily',
  }
  cron { 'clean_yum':
    command => 'yum clean all',
    user    => 'root',
    special => 'weekly',
  }
  cron { 'clean_gradle_log':
    command => 'find /home/vagrant/.gradle/daemon -name \'*.log\' -mtime +2 -delete',
    user    => 'vagrant',
    special => 'daily',
  }
  cron { 'clean_gradle_cache':
    command => 'find /home/vagrant/.gradle/caches/modules-*/files-* -atime +30 -delete',
    user    => 'vagrant',
    special => 'weekly',
  }
  cron { 'clean_gradle_wrappers':
    command => 'find /home/vagrant/.gradle/wrapper/dists/ -maxdepth 1 -mtime +120 -print0 | xargs -0 rm -r',
    user    => 'vagrant',
    special => 'weekly',
  }
  cron { 'clean_sdkman_archives':
    command => 'find /home/vagrant/.sdkman/archives/ -mtime +30 -delete',
    user    => 'vagrant',
    special => 'weekly',
  }
  cron { 'clean_vagrant_tmp':
    command => 'find /home/vagrant/.vagrant.d/tmp/ -mtime +7 -delete',
    user    => 'vagrant',
    special => 'weekly',
  }
  cron { 'clean_vagrant_cache':
    command => 'find /home/vagrant/.vagrant.d/cache/ -mtime +30 -delete',
    user    => 'vagrant',
    special => 'weekly',
  }
}
