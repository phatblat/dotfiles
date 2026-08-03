#!/usr/bin/env fish
# Browse and resume an OMP session.
function ompr
    omp --allow-home --resume $argv
end
