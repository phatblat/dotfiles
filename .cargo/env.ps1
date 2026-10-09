# rustup shell setup
if (-not ":${env:PATH}:".Contains(":$HOME/.cargo/bin:")) {
    ${env:PATH} = "$HOME/.cargo/bin:${env:PATH}";
}
