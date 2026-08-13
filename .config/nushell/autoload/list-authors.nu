# Dependencies:
#   functions: none
#   builtins:  error is-empty str join sort uniq
#   externals: git

# Collect commit authors from the current repo in various formats
export def list-authors [format?: string = "name_email"] {
    let fmt = match $format {
        "name_email" => "%an <%ae>",
        "name"       => "%an",
        "email"      => "%ae",
        "ruby"       => '"%an" => "%ae",',
        _            => $format,
    }

    ^git rev-list --all
        | lines
        | each {|commit| ^git --no-pager show -s $"--format=($fmt)" $commit }
        | str join "\n"
        | lines
        | sort
        | uniq
        | str join "\n"
}
