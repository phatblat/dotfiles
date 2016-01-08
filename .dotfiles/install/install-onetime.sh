#-------------------------------------------------------------------------------
#
# install/install-onetime.sh
# Install script for dotfiles repo.
#
#-------------------------------------------------------------------------------

echo ">>> install-onetime"
echo

# Change ownership of /usr/local
ls -ld /usr/local
sudo chown -R ${USER}:staff /usr/local

# Install Homebrew
echo "Installing Homebrew"
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# Install Homebrew cask
brew tap caskroom/cask

# ZSH
brew install zsh
zsh_path="/usr/local/bin/zsh"

TEST_CURRENT_SHELL=$(expr "${SHELL}" : '.*/\(.*\)')
if [ "${TEST_CURRENT_SHELL}" != "zsh" ]; then
	sudo echo "${zsh_path}" >> /etc/shells
	chsh -s "${zsh_path}"
fi
unset TEST_CURRENT_SHELL

# Switch to zsh and prime the shell environment
zsh
