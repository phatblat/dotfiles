export XDG_CONFIG_HOME=$HOME/.config
export MISE_PIN=1
export ENABLE_LSP_TOOL=1
export FORCE_COLOR=3

# Source Nix profile
if [ -e ~/.nix-profile/etc/profile.d/nix.sh ]; then
  . ~/.nix-profile/etc/profile.d/nix.sh
fi

# Add Nix profile bin to PATH if not already present
if [ -d ~/.nix-profile/bin ]; then
  export PATH="$HOME/.nix-profile/bin:$PATH"
fi

# LLVM (Homebrew keg-only)
export PATH="/opt/homebrew/opt/llvm/bin:$PATH"
export LDFLAGS="-L/opt/homebrew/opt/llvm/lib"
export CPPFLAGS="-I/opt/homebrew/opt/llvm/include"
export CMAKE_PREFIX_PATH="/opt/homebrew/opt/llvm"

# ICU4C (Homebrew keg-only, needed by go-icu-regex / beads)
export CGO_CFLAGS="-I/opt/homebrew/opt/icu4c/include"
export CGO_CXXFLAGS="-I/opt/homebrew/opt/icu4c/include"
export CGO_LDFLAGS="-L/opt/homebrew/opt/icu4c/lib"
export PKG_CONFIG_PATH="/opt/homebrew/opt/icu4c/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"

export PATH=$HOME/scripts:$HOME/.local/bin:/usr/local/bin:$PATH

# Homebrew setup
if (( ! $+commands[brew] )); then
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi
if [[ -d "${HOMEBREW_PREFIX}/share/zsh/site-functions" ]]; then
  fpath+=("${HOMEBREW_PREFIX}/share/zsh/site-functions")
fi

# Initialize completion system
autoload -Uz compinit
compinit

# Load custom functions via autoload (lazy-loaded on first call)
fpath=(~/.config/zsh/functions $fpath)
for _fn_file in ~/.config/zsh/functions/*(N); do
    [[ -f "$_fn_file" ]] || continue
    _fn_name="${_fn_file:t}"
    [[ "$_fn_name" == *.* ]] && continue
    autoload -Uz "$_fn_name"
done
unset _fn_file _fn_name

# Set Warp tab title to git repo name on directory change
WARP_DISABLE_AUTO_TITLE=true
precmd_functions+=(_set_tab_title)

# User configuration

# Editor configuration
export EDITOR_CLI='nvim'
export EDITOR_GUI='zed'
export WAIT_FLAG_CLI='--nofork'
export WAIT_FLAG_GUI='--wait'

# Preferred editor: zed locally, nvim over SSH
if [[ -n "$SSH_CONNECTION" ]]; then
  export EDITOR="$EDITOR_CLI"
  export WAIT_FLAG="$WAIT_FLAG_CLI"
else
  export VISUAL="$EDITOR_GUI"
  export WAIT_FLAG="$WAIT_FLAG_GUI"
fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

alias vi="nvim"
alias vim="nvim"

# Auto-Warpify
[[ "$-" == *i* ]] && printf 'P$f{"hook": "SourcedRcFileForWarp", "value": { "shell": "zsh", "uname": "Darwin" }}�'

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

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/phatblat/.cache/lm-studio/bin"
# End of LM Studio CLI section

# Added by git-ai installer on Thu Oct 23 12:10:36 MDT 2025
export PATH="/Users/phatblat/.git-ai/bin:$PATH"

# Initialize mise - version manager for tools
# NOTE: must be after other PATH modifications so mise paths take precedence
eval "$(mise activate zsh)"

# Initialize direnv - directory-based environment variables
if command -v direnv &>/dev/null; then
  eval "$(direnv hook zsh)"
fi

# Initialize starship - prompt
if command -v starship &>/dev/null; then
  eval "$(starship init zsh)"
fi

# PAI alias
alias pai='bun /Users/phatblat/.claude/skills/PAI/Tools/pai.ts'

# --- Gas Town Integration (managed by gt) ---
[[ -f "/Users/phatblat/.config/gastown/shell-hook.sh" ]] && source "/Users/phatblat/.config/gastown/shell-hook.sh"
# --- End Gas Town ---
