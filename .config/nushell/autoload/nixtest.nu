# Dependencies:
#   functions: none
#   builtins:  none
#   externals: nix-instantiate

# Test a Nix installation by instantiating the hello package from nixpkgs
export def nixtest [] {
    ^nix-instantiate "<nixpkgs>" -A hello
}
