export def rv [] {
    let remotes = ^git remote -v | lines

    if ($remotes | is-empty) {
        print "No remotes are currently defined."
        return
    }

    # Parse ^git remote -v output and get unique remotes
    let parsed_remotes = $remotes | each {|line|
        let parts = $line | split column -c '\t'
        if ($parts | length) > 0 {
            $parts | get column1
        }
    } | uniq

    # Display remotes in a table
    $parsed_remotes | each {|remote|
        {remote: $remote}
    }
}
