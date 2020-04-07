#
# Install R language things
#
class private::rlang {
  package { [ 'R', 'gstreamer1', 'gstreamer1-plugins-base', 'rstudio' ]: }
}
