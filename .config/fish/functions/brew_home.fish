function brew_home \
        --description='Prints the Homebrew home dir or the location in the cellar where formula is or would be installed.' \
        --argument-names formula

    if test -z "$BREW_HOME"
        set --export BREW_HOME (brew --prefix)
    end

    if test -n "$formula"
        echo "/usr/local/opt/$formula"
    else
        echo $BREW_HOME
    end
end
