#!/bin/bash

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

# Temp Dir
mkdir -p ~/tmp

xcode-select -p
xcode-select --install
xcodebuild -license

# Install Homebrew
echo "Installing Homebrew"
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
brew install xctool

# Homebrew Cask
brew install caskroom/cask/brew-cask
#brew cask install sublime-text # v2.0.2 last checked 2015-07-21
brew cask install iterm2
brew cask install things

# Git (PS1 is super slow with Apple's git)
brew install git
if [[ -z $(git config user.email) ]] ; then
	echo -n "Git user.name: "
	read username
	echo -n "Git user.email: "
	read useremail
	# If $XDG_CONFIG_HOME is not set or empty, $HOME/.config/git/config will be used.
	mkdir -p .config/git
	git config --file .config/git/config user.name "${username}"
	git config --file .config/git/config user.email "${useremail}"
fi

# Ruby
echo "Setting up Ruby"
brew install rbenv
brew install ruby-build
rbenv install 2.2.2
rbenv global 2.2.2
rbenv rehash

# Custom builds in ~/tmp
pushd ~/tmp > /dev/null

# Powerline
echo "Setting up Powerline"
brew install python # Required for powerline
pip install powerline-status
git clone https://github.com/powerline/fonts.git powerline-fonts
powerline-fonts/install.sh

# Screen Resolution
brew install screenresolution
screenresolution get

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

# Install Oh-My-Zsh
echo "Installing Oh-My-Zsh"
curl -L https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh | sh

# Dotfiles
# Copying last in order to force the copy over OMZ and other dir trees
# http://superuser.com/questions/61611/how-to-copy-with-cp-to-include-hidden-files-and-hidden-directories-and-their-con
shopt -s dotglob
cp -Rf $root_dir $HOME
shopt -u dotglob
echo '*' >> ~/.git/info/exclude

pushd ~
zsh

