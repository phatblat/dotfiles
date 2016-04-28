#-------------------------------------------------------------------------------
#
# install/update.sh
# Admin update script for common packages.
#
#-------------------------------------------------------------------------------

echo
echo ">>> install-update"
echo

if [[ $(dsmemberutil checkmembership -U "${USER}" -G "admin") == "user is not a member of the group" ]]; then
  echo "Only admins may run this script"
  exit 1
fi

# Xcode
xcode-select -p

# Homebrew
brew update && brew upgrade

# System Updates
softwareupdate --list
softwareupdate --install --all
