# ~/.zshenv - sourced for all zsh invocations (interactive and non-interactive)

# Add Nix profile bin to PATH
if [ -d ~/.nix-profile/bin ]; then
  export PATH="$HOME/.nix-profile/bin:$PATH"
fi

# User-managed binaries, including the mise binary itself. Needed here (rather
# than only in .zshrc) so `mise activate` can resolve `mise` for every shell
# type; .zshrc re-appends it to keep it behind Homebrew and mise-managed tools.
export PATH="$PATH:$HOME/.local/bin"

export PATH="$PATH:$HOME/.puro/bin" # Added by Puro
export PATH="$PATH:$HOME/.puro/shared/pub_cache/bin" # Added by Puro
export PATH="$PATH:$HOME/.puro/envs/default/flutter/bin" # Added by Puro
export PURO_ROOT="/Users/phatblat/.puro" # Added by Puro
export PUB_CACHE="/Users/phatblat/.puro/shared/pub_cache" # Added by Puro
