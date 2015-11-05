#-------------------------------------------------------------------------------
#
# install.sh
# Install script for dotfiles repo.
#
#-------------------------------------------------------------------------------

script_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
root_dir=$(dirname $script_dir)

echo "WARNING: This script will overwrite files in your home directory. It is only meant to be ran from a fresh user account."
echo "Are you sure you wish to continue?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) break;;
        No ) exit;;
    esac
done

# Bash options
set -o vi

# TODO: Make this script clone the dotfiles repo so that it can be executed straight from github

# Dev Dirs
mkdir -p ~/dev/ios
mkdir -p ~/dev/libgit2
mkdir -p ~/Library/QuickLook

# Temp Dir
mkdir -p ~/tmp

xcode-select -p
xcode-select --install
if [ $? -eq 0 ]; then
  open https://developer.apple.com/downloads/
fi

# Install Homebrew
echo "Installing Homebrew"
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

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
brew install carthage
brew install heroku-toolbelt
brew install nodejs
brew install speedtest_cli
brew install swiftgen
brew install terminal-notifier
brew install trash
brew install tree
brew install xctool
brew tap pivotal/tap && brew install cloudfoundary-cli
brew tap neonichu/formulae && brew install chswift

# Homebrew Cask
brew install caskroom/cask/brew-cask
brew cask install atom
brew cask install battery-guardian
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
brew cask install suspicious-package
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
rbenv install --skip-existing 2.2.3
rbenv global 2.2.3
rbenv rehash

# Ruby Gems
gem install bundler
gem install cocoapods
gem install fastlane
gem install gym
gem install nomad-cli

# Custom builds in ~/tmp
pushd ~/tmp > /dev/null

# Powerline
echo "Setting up Powerline"
brew install python # Required for powerline
pip install --upgrade pip
pip install powerline-status
git clone https://github.com/powerline/fonts.git powerline-fonts
powerline-fonts/install.sh

# VIM
if [ ! -d "~/.vim/autoload/plug.vim" ]; then
  curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

# End Custom Builds
popd > /dev/null

# ZSH
brew install zsh
zsh_path="/usr/local/bin/zsh"

TEST_CURRENT_SHELL=$(expr "$SHELL" : '.*/\(.*\)')
if [ "$TEST_CURRENT_SHELL" != "zsh" ]; then
	sudo echo "${zsh_path}" >> /etc/shells
	chsh -s "${zsh_path}"
fi
unset TEST_CURRENT_SHELL

# Dotfiles
# Copying last in order to force the copy over OMZ and other dir trees
# http://superuser.com/questions/61611/how-to-copy-with-cp-to-include-hidden-files-and-hidden-directories-and-their-con
## FIXME: This should only be done if $HOME is not a git rempo
# shopt -s dotglob
# cp -Rf "${root_dir}/" "${HOME}"
# shopt -u dotglob
# echo '*' >> ~/.git/info/exclude

pushd ~
git remote set-url origin git@github.com:phatblat/dotfiles.git
zsh
