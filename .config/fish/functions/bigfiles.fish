#!/usr/bin/env fish
# Lists the 10 biggest files in the current directory tree.
function bigfiles
    echo "File sizes in KB"
    du -ka . | sort -n -r | head -n 10
end
