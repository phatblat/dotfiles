# Sets window/tab title.
function title --argument-names name
    if test -z $name 2>/dev/null
        echo "Usage: title Tab Name"
        return 1
    end

    switch $name
        case -
            # Use default title (see fish_title).
            set --erase TAB_TITLE
        case '*'
            set --global --export TAB_TITLE $argv
    end
end
