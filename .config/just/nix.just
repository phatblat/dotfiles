# nix — Determinate Nix and home-manager

# Lists installed Nix packages
[group('nix')]
list-nix:
    #!/usr/bin/env bash
    nix-store -q --requisites ~/.nix-profile |
      xargs -I {} basename {} |
      sed 's/^[a-z0-9]\{32\}-//' |
      sed -E 's/-(lib|dev|bin|static|doc)$//' |
      sort -u |
      sed -E 's/^(.*)-([0-9].*)$/\1 \2/' |
      column -t

# Updates home-manager flake and rebuilds configuration
[group('nix')]
update-nix:
    sudo determinate-nixd upgrade
    determinate-nixd status
    nix flake update --flake {{ justfile_directory() }}/.config/home-manager
    home-manager switch --flake {{ justfile_directory() }}/.config/home-manager

# Installs Determinate Nix (macOS .pkg alternative: https://dtr.mn/determinate-nix)
[group('nix')]
install-nix:
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# Restarts the Determinate Nix daemon (ensures the store volume is mounted first)
[group('nix')]
restart-nix:
    sudo launchctl kickstart system/systems.determinate.nix-store
    sudo launchctl kickstart -k system/systems.determinate.nix-daemon

# Repairs Nix shell hooks after a macOS upgrade (`repair sequoia` recovers _nixbld users)
[group('nix')]
repair-nix:
    /nix/nix-installer repair

# Uninstalls Determinate Nix
[group('nix')]
uninstall-nix:
    /nix/nix-installer uninstall
