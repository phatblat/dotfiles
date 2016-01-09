#-------------------------------------------------------------------------------
#
# install/onetime.sh
# One-time install script for regular users.
#
#-------------------------------------------------------------------------------

echo
echo ">>> install-onetime"
echo


#-------------------------------------------------------------------------------
# Directories
#-------------------------------------------------------------------------------

# Dev Dirs
mkdir -p ~/dev/ios
mkdir -p ~/dev/libgit2
mkdir -p ~/Library/QuickLook

# Temp Dir
mkdir -p ~/tmp


#-------------------------------------------------------------------------------
# Git user config
#-------------------------------------------------------------------------------

if [[ -z $(git config user.email) ]]; then
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


#-------------------------------------------------------------------------------
# install-admin
#-------------------------------------------------------------------------------

# Run the admin install script if this user is an admin
if [[ $(dsmemberutil checkmembership -U "${USER}" -G "admin") == "user is a member of the group" ]]; then
# Hand off next phase of setup to install-admin
  echo "Invoking admin install script"
  "${HOME}/.dotfiles/install/admin.sh"
else
  echo "You are not an admin. If you get errors an admin may need to install required tools on this Mac"
fi

which -s brew
if [[ $? -ne 0 ]]; then
  echo "Homebrew is not installed."
  exit 1
fi

#-------------------------------------------------------------------------------
# Commands below here depend on tools installed by install-admin
#-------------------------------------------------------------------------------

# Ruby
echo "Setting up Ruby"
# Prime the rbenv environment
eval "$(rbenv init -)"
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

# VIM
if [[ ! -d "~/.vim/autoload/plug.vim" ]]; then
  curl -fsSLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi


#-------------------------------------------------------------------------------
# Zsh
#-------------------------------------------------------------------------------

zsh_path="$(brew --prefix)/bin/zsh"

# Get the last path component
shell_last_path_component=$(expr "${SHELL}" : '.*/\(.*\)')
if [[ ${shell_last_path_component} != "zsh" ]]; then
  sudo dscl . -change ${HOME} UserShell ${SHELL} ${zsh_path}
fi
unset shell_last_path_component

# Switch to zsh and prime the shell environment
zsh
