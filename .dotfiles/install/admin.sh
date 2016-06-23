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

# Install Homebrew cask
brew tap caskroom/cask

#-------------------------------------------------------------------------------

# Homebrew update
brew update && brew upgrade

# Git (PS1 is super slow with Apple's git)
brew install git

# Very important
brew install zsh

# Homebrew formulae
brew install antigen
brew install burl
brew install carthage

# Carthage Zsh Completion
# https://github.com/Carthage/Carthage/blob/master/Documentation/BashZshCompletion.md#zsh
ln -Fs /usr/local/Cellar/carthage/0.15/Frameworks/CarthageKit.framework/Versions/A/Scripts/carthage-zsh-completion \
  /usr/local/share/zsh/site-functions/_carthage

brew install --HEAD kylef/formulae/conche
brew install cloc
brew install coreutils
brew install direnv
brew install duti
brew install git-lfs
brew install findutils
brew install frankenstein
brew install heroku-toolbelt
brew install hub
brew install goaccess
brew install jq
brew install thoughtbot/formulae/liftoff
brew install nginx
brew install ninja
brew install nodejs
brew install rbenv
brew install rename
brew install ruby-build
brew install sloccount
brew install sourcekitten
brew install speedtest_cli
brew install kylef/formulae/swiftenv
brew install swiftgen
brew install swiftlint
brew install terminal-notifier
brew install thefuck
brew install trash
brew install travis
brew install tree
brew install xctool

# Homebrew Cask
brew install caskroom/cask/brew-cask
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
brew cask install caskroom/versions/sublime-text3
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

# Ruby - Install bundler at system level, all other gems in user dirs
# El Capitan workaround to not being able to install Bundler to /usr/bin
sudo gem install bundler --bindir /usr/local/bin

# NPM packages
npm install -g n
npm install -g ralio

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
