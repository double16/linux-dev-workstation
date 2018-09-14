#
# remote_file variant that is cached in /tmp/vagrant_cache, if it is mounted.
#
define private::cached_remote_file(
  $source,
  $verify_peer = true,
  $owner = 0,
  $group = 'root',
  $mode = '0644',
  $checksum = undef,
  $checksum_type = 'sha256',
  $target = $title,
  $cache_name = undef,
) {
  $cache_dir = '/tmp/vagrant-cache/'

  if $::vagrant_cache_mounted {

    $remote_file_source = $source
    if empty($cache_name) {
      $real_cache_file = pick(split($source, '/')[-1], pw_hash($source, 'SHA-256', '00'))
      $real_cache_name = "${cache_dir}${real_cache_file}"
    } else {
      $real_cache_name = "${cache_dir}${cache_name}"
    }

    remote_file { $real_cache_name:
      ensure        => present,
      source        => $source,
      verify_peer   => $verify_peer,
      checksum      => $checksum,
      checksum_type => $checksum_type,
    }
    ->file { $target:
      ensure => file,
      source => $real_cache_name,
      owner  => $owner,
      group  => $group,
      mode   => $mode,
    }
    
  } else {

    remote_file { $target:
      ensure        => present,
      source        => $source,
      verify_peer   => $verify_peer,
      owner         => $owner,
      group         => $group,
      mode          => $mode,
      checksum      => $checksum,
      checksum_type => $checksum_type,
    }

  }
}
