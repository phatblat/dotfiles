# Ignore changes to the given files.
function assume
    git update-index --assume-unchanged $argv
end
