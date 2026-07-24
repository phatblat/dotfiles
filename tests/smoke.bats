#!/usr/bin/env bats
# smoke.bats
# Basic smoke tests to verify CI pipeline works

load helpers/setup

@test "shellcheck is available" {
  command_exists shellcheck
}

@test "fish is available" {
  command_exists fish
}

@test "nu (nushell) is available" {
  command_exists nu
}

@test "just is available" {
  command_exists just
}

@test "mise is available" {
  command_exists mise
}

@test "mise uses npm for npm-backed tools" {
  [ "$(mise settings get npm.package_manager)" = "npm" ]
}

@test "nix is available" {
  if [[ "${CI:-}" == "true" ]]; then skip "nix not installed in CI"; fi
  command_exists nix || skip "nix not installed"
  command_exists nix
}

@test "zsh functions directory exists" {
  [[ -d "${HOME}/.config/zsh/functions" ]]
}

@test "fish functions directory exists" {
  [[ -d "${HOME}/.config/fish/functions" ]]
}

@test "nushell autoload directory exists" {
  [[ -d "${HOME}/.config/nushell/autoload" ]]
}

@test "home-manager flake exists" {
  [[ -f "${HOME}/.config/home-manager/flake.nix" ]]
}
