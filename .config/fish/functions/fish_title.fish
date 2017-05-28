# Returns the window/tab title.
#
# Default title is the name of the foreground process (e.g. fish, ping) followed
# by the present working directory canonical path.
#
# Set the TAB_TITLE value to override (see title function).
function fish_title
    if test -z $TAB_TITLE
        set -l job $_

        if test 'fish' != $job
            echo $job ' '
        end

        set -l dir (basename $PWD)

        if test $HOME = $PWD
            # Show ~ when in $HOME
            echo '~'
        else
            # Otherwise just show the current dir name
            echo $dir
        end

        return
    end

    echo $TAB_TITLE
end
