#-------------------------------------------------------------------------------
#
# install/alias.zsh
# Admin installation management aliases
#
#-------------------------------------------------------------------------------

#
# Determines whether the current $USER is in the admin group.
#
function user_is_admin {
  if [[ $(dsmemberutil checkmembership -U "${USER}" -G "admin") == "user is a member of the group" ]]; then
    return 0 # true
  else
    return 1 # false
  fi
}

if [[ user_is_admin ]]; then
  echo "user is an admin"
else
  echo "user is not an admin"
fi


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
