#-------------------------------------------------------------------------------
#
# install/update.sh
# Admin update script for common packages.
#
#-------------------------------------------------------------------------------

echo
echo ">>> install-update"
echo

# Load user_is_admin alias
source "${HOME}/.dotfiles/install/alias.zsh"

# Verify current user is an admin before proceeding
if ! user_is_admin; then
  echo "Only admins may run this script"
  exit 1
fi

#-------------------------------------------------------------------------------

# Xcode
xcode-select -p
xcversion update
xcversion list


#-------------------------------------------------------------------------------
#
# Homebrew
#

# Remove any unused tools or apps
"${HOME}/.dotfiles/install/uninstall-brew-formulae.sh"
"${HOME}/.dotfiles/install/uninstall-cask-formulae.sh"

brew update
brew upgrade
brew doctor
brew prune
brew missing

# Install any new tools or apps
"${HOME}/.dotfiles/install/install-brew-formulae.sh"
"${HOME}/.dotfiles/install/install-cask-formulae.sh"


#-------------------------------------------------------------------------------
# RubyGems

echo "Updating RubyGems"

# Workaround to no access to /usr/bin on Sierra
#   Updating rubygems-update
#   ERROR:  While executing gem ... (Errno::EPERM)
#       Operation not permitted - /usr/bin/update_rubygems
# http://stackoverflow.com/questions/33015875/operation-not-permitted-usr-bin-update-rubygems/34098613#answer-39928447
sudo gem update --bindir /usr/local/bin --system
sudo gem update --bindir /usr/local/bin

# Bundler
bundle outdated
bundle update

#-------------------------------------------------------------------------------
# System Updates

echo "Updating macOS system software"

softwareupdate --list
softwareupdate --install --all
