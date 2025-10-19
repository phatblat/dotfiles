#!/usr/bin/env fish
# List all new commits have been created with the previous command, such as after a pull.
# Defaults to using HEAD if no args are given
function new --argument-names commit
    if test -z $commit
        set -x commit 'HEAD'
    end

    set -l start_commit (rev-parse $commit'@{1}')
    set -l end_commit   (rev-parse $commit'@{0}')

    git log --boundary $start_commit..$end_commit $argv
end
