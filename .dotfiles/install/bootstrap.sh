#-------------------------------------------------------------------------------
#
# install/bootstrap.sh
# Bootstrap script for kicking off dotfiles install on a new box. Contains only
# the logic necessary to pull down the dotfiles repo. Hands off to the onetime.sh
# script for further one-time setup.
#
# Usage: Run the following command in a terminal:
#   curl -fsSL https://raw.githubusercontent.com/phatblat/dotfiles/master/.dotfiles/install/bootstrap.sh | sh
#
#-------------------------------------------------------------------------------

echo
echo ">>> install-bootstrap"
echo

# Check for existing dotfiles in user $HOME, bail if found
if [[ -d ${HOME}/.dotfiles || -d ${HOME}/.git ]]; then
  echo "Dotfiles are already installed for ${USER}@$(hostname)"
  exit 1
fi

# Xcode requred to use bundled git
xcode-select -p
xcode-select --install
if [[ $? -eq 0 ]]; then
  open https://developer.apple.com/downloads/
fi

# Clone repo to $HOME/tmp
if [[ ! -d ${HOME}/tmp ]]; then
  mkdir "${HOME}/tmp"
fi
pushd "${HOME}/tmp"
git clone https://github.com/phatblat/dotfiles.git
pushd dotfiles

# Change remote URL to use SSH
git remote set-url origin git@github.com:phatblat/dotfiles.git

# Copy Dotfiles repo into $HOME
# http://superuser.com/questions/61611/how-to-copy-with-cp-to-include-hidden-files-and-hidden-directories-and-their-con
shopt -s dotglob
cp -Rf "./" "${HOME}"
shopt -u dotglob

echo "Dotfiles now installed at ${HOME}"

popd
popd

# Hand off next phase of setup to install-onetime (in $HOME)
"${HOME}/.dotfiles/install/onetime.sh"
