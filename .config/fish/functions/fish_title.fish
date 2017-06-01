# Returns the window/tab title.
#
# Default title is the name of the foreground process (e.g. fish, ping) followed
# by the present working directory canonical path.
#
# Set the TAB_TITLE value to override (see title function).
function fish_title
    if test -n "$TAB_TITLE"
        echo $TAB_TITLE
        return
    end

    # Show a short u:h (user/host) prefix
    set -l user (string sub --length 1 $USER)
    set -l host (string sub --length 1 (hostname))
    echo $user:$host' '

    set -l job $_

    if test $job = 'man'
        # Show args for these processes. First arg is job.
        echo $argv
        # No room left for dir
        return
    else if test $job != 'fish'
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
end
