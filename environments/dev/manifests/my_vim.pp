class my_vim {
  include vim
  vim::bundle { [
     'scrooloose/syntastic',
     'altercation/vim-colors-solarized',
     'rodjek/vim-puppet',
     'maksimr/vim-jsbeautify',
     'elzr/vim-json',
     'bronson/vim-trailing-whitespace',
     'ervandew/matchem',
     'jtratner/vim-flavored-markdown',
  ]: }

}
