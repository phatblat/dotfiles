#!/usr/bin/env fish
# Count functions
function fc --wraps fl
    fl | wc -l
end
