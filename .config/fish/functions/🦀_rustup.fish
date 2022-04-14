function 🦀_rustup \
    --description='Installs rustup.'

    echo "🦀 rustup - https://rustup.rs"
    echo

    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
end
