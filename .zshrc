export XDG_CONFIG_HOME=$HOME/.config
export MISE_PIN=1
export ENABLE_LSP_TOOL=1

# If you come from bash you might have to change your $PATH.
export PATH=$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
export ZSH_THEME="clean" # set by `omz`

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git brew)

# Install Oh My Zsh if missing
if [[ ! -f "$ZSH/oh-my-zsh.sh" ]]; then
  echo "Oh My Zsh not found. Installing..."
  (
    unset ZSH
    RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  )
fi

source $ZSH/oh-my-zsh.sh
unfunction d 2>/dev/null # Remove Oh My Zsh directory stack viewer
unalias l 2>/dev/null    # Remove Oh My Zsh 'l' alias (conflicts with custom functions)

# Autoload custom functions
# Add functions directory to fpath and enable autoloading
typeset -U fpath
fpath=(~/.config/zsh/functions $fpath)
autoload -Uz ~/.config/zsh/functions/*(:t)

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# Auto-Warpify
[[ "$-" == *i* ]] && printf 'P$f{"hook": "SourcedRcFileForWarp", "value": { "shell": "zsh", "uname": "Darwin" }}�'

# delete-tag - Deletes a git tag from both the local and remote repos
function delete-tag() {
  local tag="$1"
  if [[ -z "$tag" ]]; then
    echo "Usage: delete-tag <tag>"
    return 1
  fi

  local current_branch=$(git rev-parse --abbrev-ref HEAD)
  local current_remote=$(git config branch."$current_branch".remote)

  git tag --delete "$tag"
  git push "$current_remote" --delete refs/tags/"$tag"
}

# user.name - Manages the user.name git configuration setting
function user.name() {
  git config user.name "$@"
}

# merge-base - Git merge-base wrapper
function merge-base() {
  git merge-base "$@"
}

# git-plist-filter - Converts plist data to XML format (stdin->stdout)
function git-plist-filter() {
  # had to do this because git doesn't like attaching stdin and out to plutil (waitpid error)

  # TMPDIR isn't set for ssh logins!
  local TMPDIR="${TMPDIR:-$(getconf DARWIN_USER_TEMP_DIR)}"
  local function_name="git-plist-filter"

  local TMPFILE=$(mktemp "$TMPDIR/$function_name.XXXXXX")

  # Drop stdin to temp file
  cat >"$TMPFILE"
  plutil -convert xml1 "$TMPFILE"
  cat "$TMPFILE"
  rm "$TMPFILE"
}

# format-patch - Git format-patch wrapper
function format-patch() {
  git format-patch "$@"
}

# arp-fix - Disables unicast ARP cache validation
function arp-fix() {
  if ! user_is_admin; then
    echo "You must be an admin to run this command."
    return 1
  fi

  sw_vers -productVersion

  local arp_status=$(sysctl net.link.ether.inet.arp_unicast_lim | awk '{print $2}')
  echo "net.link.ether.inet.arp_unicast_lim: $arp_status"

  local arp_fixed="net.link.ether.inet.arp_unicast_lim=0"

  if [[ $arp_status -ne 0 ]]; then
    sudo sysctl -w $arp_fixed
    arp_status=$(sysctl net.link.ether.inet.arp_unicast_lim | awk '{print $2}')

    # After installation, run the command if it now exists
    if [[ $arp_status -eq 0 ]]; then
      echo "Fixed ARP issue"
    else
      echo "Something went wrong"
      echo "net.link.ether.inet.arp_unicast_lim: $arp_status"
      return 1
    fi
  else
    echo "Runtime ARP status is correct"
  fi

  local sysctl_file="/etc/sysctl.conf"
  if [[ ! -e "$sysctl_file" ]]; then
    echo "$arp_fixed" | sudo tee "$sysctl_file"
    echo "ARP fix added to $sysctl_file"
  elif ! grep -q "$arp_fixed" "$sysctl_file"; then
    echo "$arp_fixed" | sudo tee -a "$sysctl_file"
    echo "ARP fix added to $sysctl_file"
  else
    echo "$sysctl_file already contains the ARP fix."
  fi
}

# Added by Windsurf
export PATH="/Users/phatblat/.codeium/windsurf/bin:$PATH"

# System kernel detection
export KERNEL=$(uname)

# Android SDK configuration
if is_mac; then
  export ANDROID_HOME="$HOME/Library/Android/sdk"
elif is_linux; then
  export ANDROID_HOME="$HOME/Android/Sdk"
fi

if [[ -d "$ANDROID_HOME" ]]; then
  local BUILD_TOOLS_VERSION=$(ls -1r "$ANDROID_HOME/build-tools/" 2>/dev/null | head -1)
  export NDK_VERSION=$(ls -1r "$ANDROID_HOME/ndk/" 2>/dev/null | head -1)
  export ANDROID_NDK_HOME="$ANDROID_HOME/ndk/$NDK_VERSION"

  if [[ -n "$BUILD_TOOLS_VERSION" ]]; then
    export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/emulator:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/build-tools/$BUILD_TOOLS_VERSION:$ANDROID_HOME/platform-tools:$ANDROID_NDK_HOME:$PATH"
  fi
fi

# Initialize zoxide - a smarter cd command
eval "$(zoxide init zsh)"

# Initialize mise - version manager for tools
eval "$(mise activate zsh)"

# Initialize direnv - directory-based environment variables
if command -v direnv &>/dev/null; then
  eval "$(direnv hook zsh)"
fi

# Initialize starship - prompt
if command -v starship &>/dev/null; then
  eval "$(starship init zsh)"
fi

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/phatblat/.cache/lm-studio/bin"
# End of LM Studio CLI section

# Added by git-ai installer on Thu Oct 23 12:10:36 MDT 2025
export PATH="/Users/phatblat/.git-ai/bin:$PATH"
