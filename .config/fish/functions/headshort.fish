# Prints a 7-character abbreviated sha1 hash of the current HEAD commit.
function headshort
    git rev-parse --short HEAD
end
