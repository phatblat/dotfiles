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

if ! user_is_admin; then
  echo "Only admins may run this script"
  exit 1
fi

# Change ownership of /usr/local
ls -ld /usr/local
# sudo chown -R ${USER}:staff /usr/local

which -s brew
if [[ $? -ne 0 ]]; then
  # Install Homebrew
  echo "Installing Homebrew"
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi


#-------------------------------------------------------------------------------

# Ruby - Install bundler at system level, all other gems in user dirs
# El Capitan workaround to not being able to install Bundler to /usr/bin
sudo gem install bundler --bindir /usr/local/bin

# http://stackoverflow.com/questions/41757144/your-bundle-is-locked-to-rake-12-0-0-but-that-version-could-not-be-found-in-a
sudo gem install rubygems-bundler --bindir /usr/local/bin
sudo gem regenerate_binstubs

# Install gems configured at user level
bundle install

# Xcode
xcversion update
xcversion install
xcversion install-cli-tools

# NPM packages
npm install --global fast-cli
npm install --global n
npm install --global ralio


#-------------------------------------------------------------------------------
# Custom builds
#-------------------------------------------------------------------------------

# Custom builds in ~/tmp
pushd ~/tmp > /dev/null

# Powerline for VIM
echo "Setting up Powerline"
pip install --upgrade pip
pip install powerline-status
pip install Pygments

# End Custom Builds
popd > /dev/null

# Chain the update script
"${HOME}/.dotfiles/install/update.sh"
