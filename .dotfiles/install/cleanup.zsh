#-------------------------------------------------------------------------------
#
# shell/cleanup.zsh
# Commands for system cleanup
#
#-------------------------------------------------------------------------------

function cleanup {
  gem cleanup

  # Print any warnings about the current homebrew setup, they will need to be
  # resolved manually.
  brew doctor
}
