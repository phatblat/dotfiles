# ~/.config/nixpkgs/config.nix
# Nix package configuration

{
  allowUnfreePredicate = pkg: builtins.elem (pkg.pname or (builtins.parseDrvName pkg.name).name) [
    "claude-code"
  ];
}
