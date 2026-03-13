# ~/.zshenv - sourced for all zsh invocations (interactive and non-interactive)

# Add Nix profile bin to PATH
if [ -d ~/.nix-profile/bin ]; then
  export PATH="$HOME/.nix-profile/bin:$PATH"
fi

export PATH="$PATH:$HOME/.puro/bin" # Added by Puro
export PATH="$PATH:$HOME/.puro/shared/pub_cache/bin" # Added by Puro
export PATH="$PATH:$HOME/.puro/envs/default/flutter/bin" # Added by Puro
export PURO_ROOT="/Users/phatblat/.puro" # Added by Puro
export PUB_CACHE="/Users/phatblat/.puro/shared/pub_cache" # Added by Puro
