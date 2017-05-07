# Installs and updates system and shell dependencies.
function _install
    # Fisherman - https://github.com/fisherman/fisherman#install
    set fisherDir ~/.config/fish/functions/fisher.fish

    # Follow redirects: -L, --location
    # Simple progress bar: -#, --progress-bar
    # --create-dirs
    #   When used in conjunction with the -o option, curl will create the necessary local directory hierarchy as needed. This option creates the dirs mentioned with the -o option, nothing else.
    # -o, --output <file>
    #   Write output to <file> instead of stdout.

    set url "https://raw.githubusercontent.com/fisherman/fisherman/master/fisher.fish" # "http://git.io/fisher"
    curl --location --progress-bar --create-dirs --output $fisherDir $url

    echo "Fisherman installed -> $fisherDir"

    echo "Fisherman 🐟"
    fisher mock
end
