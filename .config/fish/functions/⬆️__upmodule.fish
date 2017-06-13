# Optionally invokes an upstall module, provided the "skip" flag(s) are not given.
# Requires either 1 arg (no include/skip options), or 4+ args (include/skip
# flags & title)
function ⬆️__upmodule --argument-names module_function display_name include_flag skip_flag
    if test -z "$argv"
        echo "Usage: ⬆️__upmodule module_function [display_name include_flag skip_flag original_args]"
        return 1
    else if test (count $argv) -eq 1
        if not functions --query $module_function
            echo "Unknown function: "$module_function
            return 3
        end

        repeatchar -
        eval $module_function
    else if test (count $argv) -ge 4
        if not functions --query $module_function
            echo "Unknown function: "$module_function
            return 4
        end

        if test (count $argv) -ge 5
            set original_args $argv[5..-1]
        end

        repeatchar -

        if contains -- $skip_flag $original_args
            # Skip module if skip flag was given
            echo $display_name" (skipped)"
        else if contains -- $include_flag $original_args
            # Run module if asked for
            eval $module_function
        else
            # Otherwise, skip
            echo $display_name" (skipped)"
        end
    else
        echo "Usage: ⬆️__upmodule module_function [display_name include_flag skip_flag original_args]"
        return 2
    end
end
