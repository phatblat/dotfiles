function 🦀_rustup \
    --description='Installs rust tools.'

    echo "🦀 rustup - https://rustup.rs"
    echo

    if not command --query rustup
        echo "🦀 Installing rustup..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    end

    rustup show
    rustup check
    echo
    rustup update
end
