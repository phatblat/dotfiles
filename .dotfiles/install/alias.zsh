#-------------------------------------------------------------------------------
#
# install/alias.zsh
# Admin installation management aliases
#
#-------------------------------------------------------------------------------

lj info 'install/alias.zsh'

#
# Determines whether the current $USER is in the admin group.
# Examples:
#   if user_is_admin; then
#   if ! user_is_admin; then # Space after ! is very important
function user_is_admin {
  [[ $(dsmemberutil checkmembership -U "${USER}" -G "admin") == "user is a member of the group" ]]
}


# Only define these aliases for admin users
if user_is_admin; then
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
