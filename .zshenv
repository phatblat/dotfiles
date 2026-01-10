# ~/.zshenv - sourced for all zsh invocations (interactive and non-interactive)

# Add Nix profile bin to PATH
if [ -d ~/.nix-profile/bin ]; then
  export PATH="$HOME/.nix-profile/bin:$PATH"
fi
