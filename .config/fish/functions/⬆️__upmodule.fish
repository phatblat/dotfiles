# Optionally invokes an upstall module, provided the "skip" flag(s) are not given.
function ⬆️__upmodule --argument-names module module_name skip_flag_long skip_flag_short
    if test -z "$argv"
        echo "Usage: ⬆️__upmodule module_function module_name skip_flag_long skip_flag_short"
        return 1
    else if test (count $argv) -eq 1
        repeatchar -
        eval $module_function
    else if test (count $argv) -eq 4
        repeatchar -
        if contains -- $skip_flag_long $argv; or contains -- $skip_flag_short $argv
            echo $module_name" (skipped)"
        else
        eval $module_function
        end
    else
        echo "Usage: ⬆️__upmodule module_function module_name skip_flag_long skip_flag_short"
        return 2
    end

    repeatchar -
end
