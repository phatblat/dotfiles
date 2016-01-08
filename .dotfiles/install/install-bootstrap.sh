#-------------------------------------------------------------------------------
#
# install/install-bootstrap.sh
# Install bootstrap script for kicking off dotfiles install on a new box.
#
#-------------------------------------------------------------------------------

script_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
root_dir=$(dirname ${script_dir})


# Check for existing dotfiles, bail if found

if [[ -d ${HOME}/.dotfiles ]]; then
  echo "Dotfiles are already installed for ${USER}@$(hostname)"
fi

# Clone repo to $HOME/tmp


# Dotfiles
# http://superuser.com/questions/61611/how-to-copy-with-cp-to-include-hidden-files-and-hidden-directories-and-their-con
## FIXME: This should only be done if $HOME is not a git rempo
# shopt -s dotglob
# cp -Rf "${root_dir}/" "${HOME}"
# shopt -u dotglob
# echo '*' >> ~/.git/info/exclude

# Ensure .zshrc is symlinked
# ln -s .dotfiles/_bootstrap.zsh .zshrc

# pushd ~
# git remote set-url origin git@github.com:phatblat/dotfiles.git
# zsh
