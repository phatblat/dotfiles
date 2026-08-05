#!/usr/bin/env fish
function cmt --description='Commit with message, or open the OMP commit workflow'
    if test (count $argv) -eq 0
        omp "/git:commit"
    else
        git commit -m $argv
    end
end
