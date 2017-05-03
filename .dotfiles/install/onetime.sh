#-------------------------------------------------------------------------------
#
# install/onetime.sh
# One-time install script for regular users.
#
#-------------------------------------------------------------------------------

echo
echo ">>> install-onetime"
echo

# Load aliases
source ~/.dotfiles/install/alias.zsh


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
  git config --file "${HOME}/.config/git/config" user.name "${username}"
  git config --file "${HOME}/.config/git/config" user.email "${useremail}"
fi


#-------------------------------------------------------------------------------
# install-admin
#-------------------------------------------------------------------------------

# Run the admin install script if this user is an admin
if user_is_admin; then
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

# VIM
if [[ ! -d "~/.vim/autoload/plug.vim" ]]; then
  curl -fsSLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi


#-------------------------------------------------------------------------------
# Custom Builds
#-------------------------------------------------------------------------------

# Custom builds in ~/tmp
pushd ~/tmp > /dev/null

git clone https://github.com/powerline/fonts.git powerline-fonts
powerline-fonts/install.sh

# End Custom Builds
popd > /dev/null


#-------------------------------------------------------------------------------
# Zsh
#-------------------------------------------------------------------------------

zsh_path="$(brew --prefix)/bin/zsh"

# Get the last path component
shell_last_path_component=$(expr "${SHELL}" : '.*/\(.*\)')
if [[ ${shell_last_path_component} != "zsh" ]]; then
  if user_is_admin; then
    sudo dscl . -change ${HOME} UserShell ${SHELL} ${zsh_path}
    dscl . -read ${HOME} UserShell
  else
    echo "Have an admin run the following command:"
    echo "    sudo dscl . -change ${HOME} UserShell ${SHELL} ${zsh_path}"
    exit 0
  fi
fi
unset shell_last_path_component

# Switch to zsh and prime the shell environment
zsh
