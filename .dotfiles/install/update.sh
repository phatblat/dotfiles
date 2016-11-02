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
brew update
brew upgrade
brew doctor
brew prune
brew missing

# RubyGems update with workaround to no access to /usr/bin
#   Updating rubygems-update
#   ERROR:  While executing gem ... (Errno::EPERM)
#       Operation not permitted - /usr/bin/update_rubygems
# http://stackoverflow.com/questions/33015875/operation-not-permitted-usr-bin-update-rubygems/34098613#answer-39928447
sudo gem update --bindir /usr/local/bin --system
sudo gem update --bindir /usr/local/bin

# Bundler
bundle outdated
bundle update

# Install any new tools or apps
"${HOME}/.dotfiles/install/install-homebrew.sh"
"${HOME}/.dotfiles/install/uninstall-homebrew.sh"
"${HOME}/.dotfiles/install/install-brewcask.sh"
"${HOME}/.dotfiles/install/uninstall-brewcask.sh"

# System Updates
softwareupdate --list
softwareupdate --install --all
