# ~/.config/fish/conf.d/nix.fish
# Nix package manager PATH setup for Determinate Nix

# Add nix binaries to PATH
fish_add_path --prepend /nix/var/nix/profiles/default/bin

# Add home-manager profile if it exists
if test -d ~/.nix-profile/bin
    fish_add_path --prepend ~/.nix-profile/bin
end
