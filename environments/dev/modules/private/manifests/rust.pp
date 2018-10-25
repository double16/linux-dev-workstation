#
# rust lang and packages made in rust
#
class private::rust {
  package { ['rust', 'cargo']: }
  ->exec { 'bat':
    command => '/usr/bin/cargo install --root /usr/local bat',
    creates => '/usr/local/bin/bat',
    timeout => 1200,
  }
}
