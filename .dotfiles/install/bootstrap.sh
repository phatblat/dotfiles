#!/bin/bash -e
#-------------------------------------------------------------------------------
#
# install/bootstrap.sh
# Bootstrap script for kicking off dotfiles install on a new box. Contains only
# the logic necessary to pull down the dotfiles repo. Hands off to the onetime.sh
# script for further one-time setup.
#
# Usage: Run the following command in a terminal:
#   curl -fsSL https://raw.githubusercontent.com/phatblat/dotfiles/main/.dotfiles/install/bootstrap.sh | bash
#
#-------------------------------------------------------------------------------

echo
echo ">>> install-bootstrap"
echo

# Check for existing dotfiles in user $HOME, bail if found
if test -d ~/.dotfiles -o -d ~/.git; then
  echo "Dotfiles are already installed for $USER@$(hostname)"
  exit 1
fi

kernel=$(uname)
echo "Kernel: $kernel"

# Ensure git is installed
if ! command -v git; then
    if [ "$kernel" = "Darwin" ]; then
        # macOS
        # Install Xcode CLI tools for bundled git
        xcode-select --print-path

        # Download manually?
        # https://download.developer.apple.com/Developer_Tools/Command_Line_Tools_macOS_10.14_for_Xcode_10_Beta_2/Command_Line_Tools_macOS_10.14_for_Xcode_10_Beta_2.dmg

        if ! xcode-select --install; then
            open https://developer.apple.com/downloads/
            echo "Click the Install button to install the Xcode Command-Line Tools, then re-run this script."
            exit 1
        fi

        # TODO: accept license
        # sudo xcodebuild -license accept
    elif [ "$kernel" = "Linux" ]; then
        if command -v apt; then
            # Use apt on ubuntu
            sudo apt install git
        else
            echo "Only apt is supported for installing packages."
            exit 2
        fi
    else
        echo "Unsupported kernel: $kernel"
        return 3
    fi
fi

# Clone the .dotfiles repo into $HOME
if [ "$PWD" != "$HOME" ]; then
    pushd "$HOME"
fi

if git rev-parse --git-dir >/dev/null 2>&1; then
    echo "$HOME is already a git repo. Unable to bootstrap .dotfiles."
    exit 4
fi

git init
git remote add origin https://github.com/phatblat/dotfiles.git
git fetch
git branch --track main origin/main
git branch --set-upstream-to=origin/main main
git pull
echo "Git status before checkout:"
git status
git checkout main --force
echo "Git status after checkout:"
git status

# Change remote URL to use SSH
git remote set-url origin git@github.com:phatblat/dotfiles.git

echo "Dotfiles now installed at $HOME"

# Ensure Homebrew is installed
if ! command -v brew; then
    # Install Homebrew
    echo "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if test -z "$HOMEBREW_PREFIX"; then
    if test "$kernel" = "Darwin"; then
        if test -d /opt/homebrew; then
            HOMEBREW_PREFIX=/opt/homebrew
        else
            HOMEBREW_PREFIX=/usr/local
        fi
    elif test "$kernel" = "Linux"; then
        HOMEBREW_PREFIX=/home/linuxbrew/.linuxbrew
    fi
fi

# Only install tools if the user owns the homebrew prefix (not relevant for /usr/local as that stays owned by root)
# brew_owner_id=$(stat -f '%u' $HOMEBREW_PREFIX)
# if test $brew_owner_id = (id -u); then

# Only install if user is admin with sudo access
if sudo -v; then
    # brew shellenv won't override a current PATH
    # eval "$("$HOMEBREW_PREFIX"/bin/brew shellenv)"
    export PATH=$HOMEBREW_PREFIX/bin:$PATH

    echo
    echo "Installing shell dependencies"
    brew install bat
    brew install diff-so-fancy
    brew install direnv

    echo
    echo "Installing Fish Shell"
    brew install fish


    if test "$kernel" = "Linux"; then
        # https://docs.brew.sh/Homebrew-on-Linux

        if ! which snap >/dev/null; then
            echo "Installing Snap"
            brew install snap
        fi
    fi
fi
