# Query brew information
function bq
    if test -z "$argv"
        echo "Usage: bq [formula_name] [-- jq_filter]"
        echo "Filter examples: "
        echo "  formula                                                                           (raw json, filter with grep to find keys)"
        echo "  formula -- .[0].name                                                              (formula name)"
        echo "  formula -- .[0].linked_keg                                                        (active version)"
        echo "  --installed -- 'map(select(.keg_only == true and .linked_keg != null) | .name)'   (names of linked keg-only formulae)"
        return 1
    end

    set -l brew_args
    set -l jq_args

    set -l current_list_name brew_args
    for arg in $argv
        if test "$arg" = --
            # Start collecting args for jq
            set current_list_name jq_args
            continue
        end
        set $current_list_name $$current_list_name $arg
    end

    if test -z "$jq_args"
        # Default to simply displaying the unfiltered pretty JSON
        set jq_args .
    end

    brew info --json=v1 $brew_args \
        | jq $jq_args
end
