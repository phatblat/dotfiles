#-------------------------------------------------------------------------------
#
# install/update.sh
# Admin update script for common packages.
#
#-------------------------------------------------------------------------------

echo
echo ">>> install-update"
echo

if [ ! user_is_admin ]; then
  echo "Only admins may run this script"
  exit 1
fi

# Xcode
xcode-select -p

# Homebrew
brew update && brew upgrade

# Ruby gems
sudo gem update --system
sudo gem update --bindir /usr/local/bin

# System Updates
softwareupdate --list
softwareupdate --install --all
