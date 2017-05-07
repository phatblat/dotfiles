# Installs and updates system and shell dependencies.
function _install
    echo _install

    # Fisherman - https://github.com/fisherman/fisherman#install
    curl -Lo ~/.config/fish/functions/fisher.fish --create-dirs git.io/fisher
end
