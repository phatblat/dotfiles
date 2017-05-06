#-------------------------------------------------------------------------------
#
# install/onetime.sh
# One-time install script for regular users.
#
#-------------------------------------------------------------------------------

echo
echo ">>> install-onetime"
echo

# Load user_is_admin alias
source "${HOME}/.dotfiles/install/alias.zsh"


#-------------------------------------------------------------------------------
# Directories
#-------------------------------------------------------------------------------

# Dev Dirs
mkdir -p ~/dev/ios
mkdir -p ~/dev/libgit2
mkdir -p ~/dev/shell
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
# Lumberjack - https://github.com/molovo/lumberjack
#-------------------------------------------------------------------------------

pushd ~/dev/shell > /dev/null

echo "Installing Lumberjack - https://github.com/molovo/lumberjack"
git clone https://github.com/molovo/lumberjack.git
ln -s "${HOME}/dev/shell/lumberjack/lj" "/usr/local/bin/lj"

popd > /dev/null


#-------------------------------------------------------------------------------
# Powerline Fonts
#-------------------------------------------------------------------------------

pushd ~/tmp > /dev/null

echo "Installing PowerLine Fonts"
git clone https://github.com/powerline/fonts.git powerline-fonts
powerline-fonts/install.sh

popd > /dev/null


#-------------------------------------------------------------------------------
# Custom Shell Switch
# TODO: Use chsh? (e.g. chsh -s /usr/local/bin/fish)
#-------------------------------------------------------------------------------

# Changes the current $USER's shell using dscl. Outputs only the command to run for non-admins.
function switch_shell {
  new_shell="$1"
  shell_path="$(brew --prefix)/bin/${new_shell}"
  command="sudo dscl . -change ${HOME} UserShell ${SHELL} ${shell_path}"

  # Get the last path component
  shell_last_path_component=$(expr "${SHELL}" : '.*/\(.*\)')
  if [[ ${shell_last_path_component} != ${new_shell} ]]; then
    if user_is_admin; then
      ${command}

      echo -n "UserShell changed to "
      dscl . -read ${HOME} UserShell
    else
      echo "Have an admin run the following command:"
      echo "    ${command}"
      exit 0
    fi
  fi
  unset shell_last_path_component

  # Switch to new shell and prime the environment
  ${new_shell}
}

shells=(bash zsh fish)

echo "Your default shell is ${SHELL}, would you like to change it?"
shopt -s extglob
case "${SHELL}" in ${shells[*]}
  *bash ) current_shell="bash"
    break;;
  *zsh ) current_shell="zsh"
    break;;
  *fish ) current_shell="fish"
    break;;
esac

echo "current_shell: ${current_shell}"


select new_shell in ${shells[*]}
do
  case ${new_shell} in
    *bash ) echo "bash"
      break;;
    *zsh ) echo "zsh"
      break;;
    *fish ) echo "fish"
      break;;
  esac
done

echo "new_shell: ${new_shell}"

if [[ "${new_shell}" != "${current_shell}" ]]; then
  switch_shell "${new_shell}"
fi
