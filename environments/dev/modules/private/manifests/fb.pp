#
# Linux Framebuffer configuration
#
class private::fb {
  if empty($::resolution) {
    exec { 'unconfigure framebuffer':
      command => "grubby --update-kernel=ALL --remove-args=video=",
      path    => [ '/bin', '/sbin', '/usr/bin', '/usr/sbin' ],
      onlyif  => [ 'test -f /sys/class/graphics/fb0/name && grep -q video= /boot/grub2/grub.cfg' ],
    }
  } else {
    $video_opts = "video=\$(</sys/class/graphics/fb0/name):${::resolution}"
    exec { 'configure framebuffer':
      command => "grubby --update-kernel=ALL --args=\"${video_opts}\"",
      path    => [ '/bin', '/sbin', '/usr/bin', '/usr/sbin' ],
      unless  => [ 'test ! -f /sys/class/graphics/fb0/name', "grep -q \"${video_opts}\" /boot/grub2/grub.cfg" ],
    }
  }
}
