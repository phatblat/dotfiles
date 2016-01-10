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

if [[ $(dsmemberutil checkmembership -U "${USER}" -G "admin") == "user is not a member of the group" ]]; then
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

# Xcode
xcode-select -p
xcode-select --install
if [[ $? -eq 0 ]]; then
  open https://developer.apple.com/downloads/
fi

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
ln -Fs /usr/local/Cellar/carthage/0.10/Frameworks/CarthageKit.framework/Versions/A/Scripts/carthage-zsh-completion \
  /usr/local/share/zsh/site-functions/_carthage

brew install --HEAD kylef/formulae/conche
brew install coreutils
brew install duti
brew install git-lfs
brew install findutils
brew install heroku-toolbelt
brew install hub
brew install jq
brew install nginx
brew install nodejs
brew install rbenv
brew install rename
brew install ruby-build
brew install sourcekitten
brew install speedtest_cli
brew install kylef/formulae/swiftenv
brew install swiftgen
brew install swiftlint
brew install terminal-notifier
brew install thefuck
brew install trash
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
brew cask install iterm2
brew cask install kaleidoscope
brew cask install macdown
brew cask install quickradar
brew cask install simpholders
brew cask install soundcleod
#brew cask install sublime-text # v2.0.2 last checked 2015-07-21
brew cask install textexpander
brew cask install things
brew cask install tower

# QuickLook plugins
brew cask install betterzipql
brew cask install cert-quicklook
brew cask install provisioning
brew cask install qlcolorcode
brew cask install qlimagesize
brew cask install qlmarkdown
brew cask install qlprettypatch
brew cask install qlstephen   # preview files without an extension as text
brew cask install quicklook-csv
brew cask install quicklook-json
brew cask install webpquicklook

# NPM packages
npm install -g n
npm install -g ralio

# Atom packages
apm install dash


#-------------------------------------------------------------------------------
# Ruby
#-------------------------------------------------------------------------------
echo "Setting up Ruby"
# Prime the rbenv environment
eval "$(rbenv init -)"
rbenv install --skip-existing 2.2.2

# Each user needs to set their own ruby version
rbenv global 2.2.2
rbenv rehash


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
git clone https://github.com/powerline/fonts.git powerline-fonts
powerline-fonts/install.sh

# End Custom Builds
popd > /dev/null

# Chain the update script
"${HOME}/.dotfiles/install/update.sh"
