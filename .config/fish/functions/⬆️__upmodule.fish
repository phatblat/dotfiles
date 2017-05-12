# Optionally invokes an upstall module, provided the "skip" flag(s) are not given.
function ⬆️__upmodule --argument-names module_function display_name skip_flag_long skip_flag_short
    if test -z "$argv"
        echo "Usage: ⬆️__upmodule module_function [display_name skip_flag_long skip_flag_short original_args]"
        return 1
    else if test (count $argv) -eq 1
        if not functions --query $module_function
            echo "Unknown function: "$module_function
            return 2
        end

        repeatchar -
        eval $module_function
    else if test (count $argv) -ge 4
        if not functions --query $module_function
            echo "Unknown function: "$module_function
            return 2
        end

        if test (count $argv) -ge 5
            set original_args $argv[5..-1]
        end

        repeatchar -
        if contains -- $skip_flag_long $original_args; or contains -- $skip_flag_short $original_args
            echo $display_name" (skipped)"
        else
            eval $module_function
        end
    else
        echo "Usage: ⬆️__upmodule module_function [display_name skip_flag_long skip_flag_short original_args]"
        return 2
    end
end
