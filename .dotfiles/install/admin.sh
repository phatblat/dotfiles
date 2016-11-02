#-------------------------------------------------------------------------------
#
# install/admin.sh
# One-time admin install script for dotfiles repo.
#
#-------------------------------------------------------------------------------

echo
echo ">>> install-admin"
echo

# Verify current user is an admin before proceeding

if [ ! user_is_admin ]; then
  echo "Only admins may run this script"
  exit 1
fi

# Change ownership of /usr/local
ls -ld /usr/local
sudo chown -R ${USER}:staff /usr/local

# Install Homebrew
echo "Installing Homebrew"
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

./install-homebrew.sh

#-------------------------------------------------------------------------------

# Homebrew Cask
brew cask install atom
brew cask install charles
brew cask install dayone-cli
brew cask install fabric
brew cask install geekbench
brew cask install github-desktop
brew cask install google-chrome
brew cask install hipchat
brew cask install ios-console
brew cask install istat-menus
# brew cask install iterm2 # Disabled until v3 is released
brew cask install caskroom/versions/iterm2-beta
brew cask install kaleidoscope
brew cask install macdown
brew cask install quickradar
brew cask install simpholders
# brew cask install sublime-text # v2.0.2 last checked 2015-07-21
brew cask install sublime-text-dev
brew cask install textexpander
brew cask install things
brew cask install tower

# QuickLook plugins
brew cask install betterzipql
brew cask install cert-quicklook
brew cask install cocoapods
brew cask install provisioning
brew cask install qlcolorcode
brew cask install qlimagesize
brew cask install qlmarkdown
brew cask install qlprettypatch
brew cask install qlstephen   # preview files without an extension as text
brew cask install quicklook-csv
brew cask install quicklook-json
brew cask install webpquicklook

# RubyGems update with workaround to no access to /usr/bin
#   Updating rubygems-update
#   ERROR:  While executing gem ... (Errno::EPERM)
#       Operation not permitted - /usr/bin/update_rubygems
# http://stackoverflow.com/questions/33015875/operation-not-permitted-usr-bin-update-rubygems/34098613#answer-39928447
sudo gem update --bindir /usr/local/bin --system

# Ruby - Install bundler at system level, all other gems in user dirs
# El Capitan workaround to not being able to install Bundler to /usr/bin
sudo gem install bundler --bindir /usr/local/bin

# NPM packages
npm install --global fast-cli
npm install --global n
npm install --global ralio

# Atom packages
apm install dash


#-------------------------------------------------------------------------------
# Custom builds
#-------------------------------------------------------------------------------

# Custom builds in ~/tmp
pushd ~/tmp > /dev/null

# Powerline
echo "Setting up Powerline"
brew install python # Required for powerline
pip install --upgrade pip
pip install powerline-status
pip install Pygments

# End Custom Builds
popd > /dev/null

# Chain the update script
"${HOME}/.dotfiles/install/update.sh"
