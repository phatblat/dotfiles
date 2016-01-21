#-------------------------------------------------------------------------------
#
# install/alias.zsh
# Admin installation management aliases
#
#-------------------------------------------------------------------------------

# Only define these aliases for admin users
if [[ $(dsmemberutil checkmembership -U "${USER}" -G "admin") == "user is a member of the group" ]]; then

  # update
  # Invokes the admin package update script
  alias update='~/.dotfiles/install/update.sh'

  # cleanup
  # Cleans up old gems, checks Homebrew
  function cleanup {
    gem cleanup

    # Print any warnings about the current homebrew setup, they will need to be
    # resolved manually.
    brew doctor

    # Check homebrew cask
    brew cask doctor
  }

fi
