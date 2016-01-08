#-------------------------------------------------------------------------------
#
# install/install.sh
# Install script for common packages.
#
#-------------------------------------------------------------------------------

echo ">>> install"
echo

# Dev Dirs
mkdir -p ~/dev/ios
mkdir -p ~/dev/libgit2
mkdir -p ~/Library/QuickLook

# Temp Dir
mkdir -p ~/tmp

# Xcode
xcode-select -p
xcode-select --install
if [ $? -eq 0 ]; then
  open https://developer.apple.com/downloads/
fi

# Homebrew
which -s brew
if [ $? -eq 0 ]; then
  brew update && brew upgrade
else
  # Install Homebrew
  echo "Installing Homebrew"
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# Git (PS1 is super slow with Apple's git)
brew install git
if [[ -z $(git config user.email) ]] ; then
	echo -n "Git user.name: "
	read username
	echo -n "Git user.email: "
	read useremail

  # ~/.gitconfig is tracked and shared. Sensitive or machine-specific data is
  # stored in the alternate global config file.
	# > If $XDG_CONFIG_HOME is not set or empty, $HOME/.config/git/config will be used.
	mkdir -p .config/git
	git config --file .config/git/config user.name "${username}"
	git config --file .config/git/config user.email "${useremail}"
fi

# Homebrew formulae
brew install antigen
brew install burl
brew install carthage
brew install --HEAD kylef/formulae/conche
brew install duti
brew install git-lfs
brew install heroku-toolbelt
brew install hub
brew install nodejs
brew install sourcekitten
brew install speedtest_cli
brew install kylef/formulae/swiftenv
brew install jq
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

# Ruby
echo "Setting up Ruby"
brew install rbenv
brew install ruby-build
rbenv install --skip-existing 2.2.2
rbenv global 2.2.2
rbenv rehash

# Ruby Gems
gem install bundler
gem install cocoapods
gem install cocoapods-deintegrate
gem install fastlane
gem install github-pages
gem install gym
gem install nomad-cli
gem install octopress
gem install octopress-debugger
gem install xcode-install

# Carthage Zsh Completion
# https://github.com/Carthage/Carthage/blob/master/Documentation/BashZshCompletion.md#zsh
ln -Fs /usr/local/Cellar/carthage/0.10/Frameworks/CarthageKit.framework/Versions/A/Scripts/carthage-zsh-completion \
  /usr/local/share/zsh/site-functions/_carthage

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

# VIM
if [ ! -d "~/.vim/autoload/plug.vim" ]; then
  curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

# End Custom Builds
popd > /dev/null
