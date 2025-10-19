#!/usr/bin/env fish
function 🦀_rustup \
    --description='Installs rust tools.'

    echo "🦀 rustup - https://rustup.rs"
    echo

    if not command --query rustup
        echo "🦀 Installing rustup..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    end

    echo "Reloading fish to pick up new cargo path"
    reload

    rustup show
    rustup check
    echo
    rustup update

    set --local plugins \
        cargo-readme

    for plugin in $plugins
        if test -f $HOME/.cargo/bin/$plugin
            continue
        end
        echo "🦀 Installing plugin: $plugin"
        cargo install $plugin
    end
end
