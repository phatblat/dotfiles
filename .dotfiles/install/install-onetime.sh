#-------------------------------------------------------------------------------
#
# install/install-onetime.sh
# Install script for dotfiles repo.
#
#-------------------------------------------------------------------------------

echo "WARNING: This script will overwrite files in your home directory. It is only meant to be ran from a fresh user account."
echo "Are you sure you wish to continue?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) break;;
        No ) exit;;
    esac
done

# Change ownership of /usr/local
# Install Homebrew
# Install Homebrew cask

# ZSH
brew install zsh
zsh_path="/usr/local/bin/zsh"

TEST_CURRENT_SHELL=$(expr "$SHELL" : '.*/\(.*\)')
if [ "$TEST_CURRENT_SHELL" != "zsh" ]; then
	sudo echo "${zsh_path}" >> /etc/shells
	chsh -s "${zsh_path}"
fi
unset TEST_CURRENT_SHELL
