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
if [[ -d ~/.dotfiles || -d ~/.git ]]; then
  echo "Dotfiles are already installed for $USER@$(hostname)"
  exit 1
fi

# Xcode requred to use bundled git
xcode-select -p
xcode-select --install
if [[ $? -eq 0 ]]; then
  open https://developer.apple.com/downloads/
fi

# Clone the .dotfiles repo into $HOME
if [[ $PWD != $HOME ]]; then
    push $HOME
fi

if git rev-parse --git-dir >/dev/null 2>&1; then
    echo "$HOME is already a git repo. Unable to bootstrap .dotfiles."
    exit 1
end

git init
git remote add origin https://github.com/phatblat/dotfiles.git
git branch --set-upstream-to=origin/master master
git pull
echo "Git status before checkout:"
git status
git checkout master --force
echo "Git status after checkout:"
git status

# Change remote URL to use SSH
git remote set-url origin git@github.com:phatblat/dotfiles.git

echo "Dotfiles now installed at $HOME"
