#-------------------------------------------------------------------------------
#
# shell/cleanup.zsh
# Commands for system cleanup
#
#-------------------------------------------------------------------------------

function cleanup {
  gem cleanup
  brew doctor
}
