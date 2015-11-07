#-------------------------------------------------------------------------------
#
# install/install-onetime.sh
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

# TODO: Make this script clone the dotfiles repo so that it can be executed straight from github

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
# http://superuser.com/questions/61611/how-to-copy-with-cp-to-include-hidden-files-and-hidden-directories-and-their-con
## FIXME: This should only be done if $HOME is not a git rempo
# shopt -s dotglob
# cp -Rf "${root_dir}/" "${HOME}"
# shopt -u dotglob
# echo '*' >> ~/.git/info/exclude

pushd ~
git remote set-url origin git@github.com:phatblat/dotfiles.git
zsh
