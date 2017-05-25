# Returns the window/tab title.
#
# Default title is the name of the foreground process (e.g. fish, ping) followed
# by the present working directory canonical path.
#
# Set the TAB_TITLE value to override (see title function).
function fish_title
    if test -z $TAB_TITLE
        echo $_ ' '
        pwd
        return
    end

    echo $TAB_TITLE
end
