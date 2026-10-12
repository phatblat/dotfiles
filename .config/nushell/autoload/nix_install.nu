# nix_install - Installs nix tools (converted from ❄️_nix)
export def nix_install [] {
    print "❄️ Nix - https://nixos.org/download.html#nix-install-macos"
    print ""

    if (which nix-channel | is-empty) {
        print "❄️ Installing nix..."
        ^sh -c "curl -L https://nixos.org/nix/install | sh -s -- --daemon"

        nixtest

        ^nix-channel --add https://github.com/nix-community/home-manager/archive/release-22.05.tar.gz home-manager
        ^nix-channel --update
    }
}
