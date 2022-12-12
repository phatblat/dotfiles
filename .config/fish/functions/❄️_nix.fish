function ❄️_nix \
    --description='Installs rust tools.'

    echo "❄️ Nix - https://nixos.org/download.html#nix-install-macos"
    echo

    if not command --query nix-channel
        echo "❄️ Installing nix..."
        curl -L https://nixos.org/nix/install | sh -s -- --daemon

        nixtest

        nix-channel --add https://github.com/nix-community/home-manager/archive/release-22.05.tar.gz home-manager
        nix-channel --update
    end

end
