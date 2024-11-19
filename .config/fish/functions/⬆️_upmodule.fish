function ⬆️_upmodule \
    --description='Optionally invokes an upstall module, provided the "skip" flag(s) are not given. Requires either 1 arg (no include/skip options), or 4+ args (include/skip flags & title)' \
    --argument-names \
        module_function \
        display_name \
        include_flag \
        skip_flag

    # no args
    if test -z "$argv"
        error "Usage: ⬆️_upmodule module_function [display_name include_flag skip_flag original_args]"
        return 1
    end

    if not functions --query $module_function
        echo "Unknown function: "$module_function
        return 2
    end

    # 1 arg
    if test (count $argv) -eq 1
        repeatchar -
        eval $module_function

    # 4+ args
    else if test (count $argv) -ge 4
        if not functions --query $module_function
            echo "Unknown function: "$module_function
            return 4
        end

        # args 5+ are the original args passed to upstall
        if test (count $argv) -ge 5
            set original_args $argv[5..-1]
        end

        if contains -- $skip_flag $original_args
            # Skip module if skip flag was given
            repeatchar -
            echo $display_name" (skipped)"
        else if contains -- $include_flag $original_args
            # Run module if asked for
            repeatchar -
            eval $module_function
        else
            # Otherwise, skip
            # echo $display_name" (skipped)"
        end
    else
        echo "Usage: ⬆️_upmodule module_function [display_name include_flag skip_flag original_args]"
        return 2
    end
end
