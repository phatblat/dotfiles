# Dependencies:
#   functions: jq
#   builtins:  print is-empty
#   externals: brew

# Query brew information with optional jq filter
# Usage: bq [--filter FILTER] [formula_name | --installed | --cask ...]
# Examples:
#   bq git                                                         (raw json)
#   bq git --filter '.[0].name'                                    (formula name)
#   bq git --filter '.[0].linked_keg'                              (active version)
#   bq --installed --filter 'map(select(.linked_keg != null) | .name)'
export def bq [
    --filter (-f): string = ".",  # jq filter to apply (default: "." for raw output)
    ...brew_args: string          # brew info arguments (formula name, --installed, etc.)
] {
    if ($brew_args | is-empty) {
        print "Usage: bq [--filter FILTER] formula_name"
        print "       bq [--filter FILTER] --installed"
        print "Filter examples:"
        print "  bq git --filter '.[0].name'          (formula name)"
        print "  bq git --filter '.[0].linked_keg'    (active version)"
        error make { msg: "bq: no arguments provided" }
    }

    ^brew info --json=v1 ...$brew_args | jq $filter
}
