# Installs and updates system and shell dependencies.
function _install
    echo _install

    # Fisherman - https://github.com/fisherman/fisherman#install
    set fisherDir ~/.config/fish/functions/fisher.fish
    # if test -e $fisherDir

    # Follow redirects: -L, --location
    # Simple progress bar: -#, --progress-bar
    # --create-dirs
    #   When used in conjunction with the -o option, curl will create the necessary local directory hierarchy as needed. This option creates the dirs mentioned with the -o option, nothing else.
    # -o, --output <file>
    #   Write output to <file> instead of stdout.

    set url "http://git.io/fisher"
    # set url "https://raw.githubusercontent.com/fisherman/fisherman/master/fisher.fish"
    curl --location --progress-bar --create-dirs --output $fisherDir $url

    # end
    echo "Fisherman installed -> $fisherDir"
    echo "Fisherman 🐟"

    fisher mock
end
