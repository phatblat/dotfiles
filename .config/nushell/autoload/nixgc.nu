# Dependencies:
#   functions: none
#   builtins:  none
#   externals: nix-collect-garbage nix-store

# Run nix garbage collection and optimise the nix store
export def nixgc [] {
    ^nix-collect-garbage -d
    ^nix-store --optimise
}
