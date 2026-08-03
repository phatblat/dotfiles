#!/usr/bin/env fish
# Continue the most recent OMP session.
function ompc
    omp --allow-home --continue $argv
end
