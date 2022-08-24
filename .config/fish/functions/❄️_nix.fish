function ❄️_nix \
    --description='Installs rust tools.'

    echo "❄️ Nix - https://nixos.org/download.html#nix-install-macos"
    echo

    if not command --query nix-channel
        echo "❄️ Installing nix..."
        curl -L https://nixos.org/nix/install | sh
    end

end
