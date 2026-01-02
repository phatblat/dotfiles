# Source cargo env if it exists (rustup creates this file)
if test -f "$HOME/.cargo/env.fish"
    source "$HOME/.cargo/env.fish"
end
