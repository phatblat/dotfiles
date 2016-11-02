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


#-------------------------------------------------------------------------------

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
pip install --upgrade pip
pip install powerline-status
pip install Pygments

# End Custom Builds
popd > /dev/null

# Chain the update script
"${HOME}/.dotfiles/install/update.sh"
