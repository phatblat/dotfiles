#!/usr/bin/env fish
function brew_home \
        --description='Prints the Homebrew home dir or the location in the cellar where formula is or would be installed.' \
        --argument-names formula

    if test -z "$BREW_HOME"
        if type -q brew
            set --export BREW_HOME (brew --prefix)
        else
            if is_mac
                if is_arm
                    set --export BREW_HOME /opt/homebrew
                else
                    set --export BREW_HOME /usr/local
                end
            else if is_linux
                set --export BREW_HOME /home/linuxbrew/.linuxbrew
            end
        end
    end

    if test -n "$formula"
        echo "$BREW_HOME/opt/$formula"
    else
        echo $BREW_HOME
    end
end
