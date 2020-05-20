# zeal - documentation browser like Dash on Mac
# - user contributed doc feeds at http://zealusercontributions.herokuapp.com/
# - official Dash user contrib feed at http://sanfrancisco.kapeli.com/feeds/zzz/user_contributed/build/index.json
# - example feed download: http://newyork.kapeli.com/feeds/zzz/user_contributed/build/Google_App_Engine-Python/GAE-Python.tgz
# - official Dash feeds at https://github.com/Kapeli/feeds
class private::zeal {
  package { 'zeal': }

  $conf = '/home/vagrant/.config/Zeal/Zeal.conf'
  $docsets = '/home/vagrant/.local/share/Zeal/docsets'

  $darkmode = pick($::theme, lookup('theme::default')) ? {
    /light/ => 'false',
    /dark/  => 'true',
    default => undef,
  }
  $darkmode_ensure = empty($darkmode) ? {
    true    => absent,
    default => present,
  }

  file { '/home/vagrant/.config/Zeal':
    ensure => directory,
    mode   => '0755',
    owner  => 'vagrant',
    group  => 'vagrant',
  }

  file { '/home/vagrant/.local/share/Zeal':
    ensure => directory,
    mode   => '0755',
    owner  => 'vagrant',
    group  => 'vagrant',
  }

  file { $docsets:
    ensure => directory,
    mode   => '0755',
    owner  => 'vagrant',
    group  => 'vagrant',
  }

  file { $conf:
    ensure => present,
    mode   => '0644',
    owner  => 'vagrant',
    group  => 'vagrant',
  }

  ini_setting { 'Zeal dark mode':
    ensure  => $darkmode_ensure,
    path    => $conf,
    section => 'content',
    setting => 'dark_mode',
    value   => $darkmode,
    require => File['/home/vagrant/.config/Zeal'],
  }

  ini_setting { 'Zeal doc sets':
    path    => $conf,
    section => 'docsets',
    setting => 'path',
    value   => $docsets,
    require => File['/home/vagrant/.config/Zeal'],
  }

  file { "/tmp/vagrant-cache/zeal-docsets":
    ensure => directory,
    mode   => '0755',
    owner  => 'vagrant',
    group  => 'vagrant',
  }

  [
    ['http://newyork.kapeli.com/feeds/Bash.tgz', 'Bash'],
    ['http://newyork.kapeli.com/feeds/Docker.tgz', 'Docker'],
    ['http://newyork.kapeli.com/feeds/Gradle_DSL.tgz', 'Gradle DSL'],
    ['http://newyork.kapeli.com/feeds/Gradle_Groovy_API.tgz', 'Gradle Groovy API'],
    ['http://newyork.kapeli.com/feeds/Gradle_Java_API.tgz', 'Gradle Java API'],
    ['http://newyork.kapeli.com/feeds/Gradle_User_Guide.tgz', 'Gradle User Guide'],
    ['http://newyork.kapeli.com/feeds/Groovy.tgz', 'Groovy'],
    ['http://newyork.kapeli.com/feeds/Groovy_JDK.tgz', 'Groovy JDK'],
    ['http://newyork.kapeli.com/feeds/JavaScript.tgz', 'JavaScript'],
    ['http://sanfrancisco.kapeli.com/feeds/Angular.tgz', 'Angular'],
    ['http://sanfrancisco.kapeli.com/feeds/Bootstrap_4.tgz', 'Bootstrap 4'],
    ['http://sanfrancisco.kapeli.com/feeds/Chef.tgz', 'Chef'],
    ['http://sanfrancisco.kapeli.com/feeds/Font_Awesome.tgz', 'Font_Awesome'],
    ['http://newyork.kapeli.com/feeds/Go.tgz', 'Go'],
    ['http://newyork.kapeli.com/feeds/HTML.tgz', 'HTML'],
    ['http://sanfrancisco.kapeli.com/feeds/Java_SE12.tgz', 'Java'],
    ['http://sanfrancisco.kapeli.com/feeds/Lua_5.3.tgz', 'Lua'],
    ['http://sanfrancisco.kapeli.com/feeds/Markdown.tgz', 'Markdown'],
    ['http://sanfrancisco.kapeli.com/feeds/MongoDB.tgz', 'MongoDB'],
    ['http://newyork.kapeli.com/feeds/NodeJS.tgz', 'NodeJS'],
    ['http://newyork.kapeli.com/feeds/Puppet.tgz', 'Puppet'],
    ['http://newyork.kapeli.com/feeds/R.tgz', 'R'],
    ['http://newyork.kapeli.com/feeds/Ruby_2.tgz', 'Ruby'],
    ['http://newyork.kapeli.com/feeds/TypeScript.tgz', 'TypeScript'],
    ['http://sanfrancisco.kapeli.com/feeds/Vagrant.tgz', 'Vagrant'],
    ['http://newyork.kapeli.com/feeds/Vim.tgz', 'Vim'],
    ['http://sanfrancisco.kapeli.com/feeds/VueJS.tgz', 'VueJS'],
    ['http://newyork.kapeli.com/feeds/zzz/user_contributed/build/Terraform/Terraform.tgz', 'Terraform'],
    ['http://kapeli.com/feeds/zzz/user_contributed/build/BootstrapVue/bootstrap-vue.tgz', 'bootstrap-vue'],
    ['http://sanfrancisco.kapeli.com/feeds/zzz/user_contributed/build/Geb/Geb.tgz', 'Geb'],
    ['http://kapeli.com/feeds/zzz/user_contributed/build/Packer/Packer.tgz', 'Packer'],
    ['http://newyork.kapeli.com/feeds/zzz/user_contributed/build/kafka/Kafka.tgz', 'Kafka'],
    ['http://sanfrancisco.kapeli.com/feeds/zzz/user_contributed/build/RxJS/RxJS.tgz', 'RxJS'],
    ['http://sanfrancisco.kapeli.com/feeds/zzz/user_contributed/build/Kotlin/kotlin.tgz', 'kotlin'],
    ['http://sanfrancisco.kapeli.com/feeds/zzz/user_contributed/build/Powershell/Powershell.tgz', 'Powershell'],
    ['http://sanfrancisco.kapeli.com/feeds/zzz/user_contributed/build/Kubernetes/Kubernetes.tgz', 'Kubernetes'],
    ['http://sanfrancisco.kapeli.com/feeds/zzz/user_contributed/build/RxJava/RxJava.tgz', 'RxJava'],
  ].each |$e| {
    $feed = $e[0]
    $target_dirname = $e[1]
    $filename = "${strftime('%Y-%m')}-${split($feed, '/')[-1]}"
    archive { "/tmp/vagrant-cache/zeal-docsets/${filename}":
        ensure        => present,
        extract       => true,
        extract_path  => $docsets,
        source        => $feed,
        creates       => "${$docsets}/${$target_dirname}.docset",
        cleanup       => false,
        user          => 'vagrant',
        group         => 'vagrant',
        require       => [File[$docsets], File['/tmp/vagrant-cache/zeal-docsets']],
      }
  }
}
